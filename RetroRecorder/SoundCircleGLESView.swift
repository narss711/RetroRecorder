import GLKit
import OpenGLES
import SwiftUI

struct SoundCircleGLESView: UIViewRepresentable {
    let spectrum: [Double]
    let waveform: [Double]
    let isActive: Bool

    func makeCoordinator() -> Renderer {
        Renderer()
    }

    func makeUIView(context: Context) -> GLKView {
        let view = GLKView(frame: .zero, context: context.coordinator.context)
        view.drawableColorFormat = .RGBA8888
        view.drawableDepthFormat = .formatNone
        view.drawableStencilFormat = .formatNone
        view.drawableMultisample = .multisampleNone
        view.enableSetNeedsDisplay = false
        view.isUserInteractionEnabled = false
        view.backgroundColor = .black
        view.accessibilityLabel = "OpenGL ES realtime sound circle"
        view.delegate = context.coordinator
        context.coordinator.attach(view)
        return view
    }

    func updateUIView(_ view: GLKView, context: Context) {
        context.coordinator.update(
            frame: ShadertoyAudioFrame(spectrum: spectrum, waveform: waveform),
            isActive: isActive
        )
    }

    static func dismantleUIView(_ view: GLKView, coordinator: Renderer) {
        view.delegate = nil
        coordinator.stop()
    }

    final class Renderer: NSObject, GLKViewDelegate {
        fileprivate let context: EAGLContext

        private let dataLock = NSLock()
        private weak var view: GLKView?
        private var displayLink: CADisplayLink?
        private var program: GLuint = 0
        private var pendingAudioBytes = Array(repeating: UInt8(0), count: ShadertoyAudioFrame.width * 2)
        private var energy: GLfloat = 0
        private var audioTexture: GLuint = 0
        private var startedAt = CACurrentMediaTime()
        private var resolutionLocation: GLint = -1
        private var timeLocation: GLint = -1
        private var energyLocation: GLint = -1
        private var channelLocation: GLint = -1

        override init() {
            guard let context = EAGLContext(api: .openGLES3) else {
                fatalError("OpenGL ES 3 is unavailable")
            }
            self.context = context
            super.init()
            configureProgram()
        }

        deinit {
            stop()
        }

        func attach(_ view: GLKView) {
            self.view = view
        }

        func update(frame: ShadertoyAudioFrame, isActive: Bool) {
            dataLock.lock()
            pendingAudioBytes = frame.textureBytes
            energy = frame.energy
            dataLock.unlock()

            if isActive {
                startDisplayLink()
            } else {
                stopDisplayLink()
                view?.display()
            }
        }

        func stop() {
            stopDisplayLink()
            EAGLContext.setCurrent(context)
            if program != 0 {
                glDeleteProgram(program)
                program = 0
            }
            if audioTexture != 0 {
                glDeleteTextures(1, &audioTexture)
                audioTexture = 0
            }
            if EAGLContext.current() === context {
                EAGLContext.setCurrent(nil)
            }
        }

        func glkView(_ view: GLKView, drawIn rect: CGRect) {
            guard program != 0 else { return }
            EAGLContext.setCurrent(context)
            glViewport(0, 0, GLsizei(view.drawableWidth), GLsizei(view.drawableHeight))
            glClearColor(0.002, 0.004, 0.009, 1)
            glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
            glUseProgram(program)

            dataLock.lock()
            let audioBytes = pendingAudioBytes
            let currentEnergy = energy
            dataLock.unlock()

            glUniform2f(resolutionLocation, GLfloat(view.drawableWidth), GLfloat(view.drawableHeight))
            glUniform1f(timeLocation, GLfloat(CACurrentMediaTime() - startedAt))
            glUniform1f(energyLocation, currentEnergy)
            glActiveTexture(GLenum(GL_TEXTURE0))
            glBindTexture(GLenum(GL_TEXTURE_2D), audioTexture)
            audioBytes.withUnsafeBytes { bytes in
                glTexSubImage2D(
                    GLenum(GL_TEXTURE_2D),
                    0,
                    0,
                    0,
                    GLsizei(ShadertoyAudioFrame.width),
                    2,
                    GLenum(GL_RED),
                    GLenum(GL_UNSIGNED_BYTE),
                    bytes.baseAddress
                )
            }
            glUniform1i(channelLocation, 0)
            glDrawArrays(GLenum(GL_TRIANGLES), 0, 3)
        }

        @objc private func displayFrame() {
            view?.display()
        }

        private func startDisplayLink() {
            guard displayLink == nil else { return }
            let link = CADisplayLink(target: self, selector: #selector(displayFrame))
            link.preferredFramesPerSecond = 60
            link.add(to: .main, forMode: .common)
            displayLink = link
        }

        private func stopDisplayLink() {
            displayLink?.invalidate()
            displayLink = nil
        }

        private func configureProgram() {
            EAGLContext.setCurrent(context)
            let vertexShader = compileShader(type: GLenum(GL_VERTEX_SHADER), source: Self.vertexSource)
            let fragmentShader = compileShader(type: GLenum(GL_FRAGMENT_SHADER), source: Self.fragmentSource)
            guard vertexShader != 0, fragmentShader != 0 else { return }

            let program = glCreateProgram()
            glAttachShader(program, vertexShader)
            glAttachShader(program, fragmentShader)
            glLinkProgram(program)
            glDeleteShader(vertexShader)
            glDeleteShader(fragmentShader)

            var linked: GLint = 0
            glGetProgramiv(program, GLenum(GL_LINK_STATUS), &linked)
            guard linked == GL_TRUE else {
                glDeleteProgram(program)
                return
            }

            self.program = program
            resolutionLocation = glGetUniformLocation(program, "uResolution")
            timeLocation = glGetUniformLocation(program, "uTime")
            energyLocation = glGetUniformLocation(program, "uEnergy")
            channelLocation = glGetUniformLocation(program, "uChannel0")

            glGenTextures(1, &audioTexture)
            glActiveTexture(GLenum(GL_TEXTURE0))
            glBindTexture(GLenum(GL_TEXTURE_2D), audioTexture)
            glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GL_LINEAR)
            glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), GL_LINEAR)
            glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GL_CLAMP_TO_EDGE)
            glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GL_CLAMP_TO_EDGE)
            let emptyBytes = Array(repeating: UInt8(0), count: ShadertoyAudioFrame.width * 2)
            emptyBytes.withUnsafeBytes { bytes in
                glTexImage2D(
                    GLenum(GL_TEXTURE_2D),
                    0,
                    GL_R8,
                    GLsizei(ShadertoyAudioFrame.width),
                    2,
                    0,
                    GLenum(GL_RED),
                    GLenum(GL_UNSIGNED_BYTE),
                    bytes.baseAddress
                )
            }
        }

        private func compileShader(type: GLenum, source: String) -> GLuint {
            let shader = glCreateShader(type)
            source.withCString { sourcePointer in
                var pointer: UnsafePointer<GLchar>? = UnsafePointer(sourcePointer)
                glShaderSource(shader, 1, &pointer, nil)
            }
            glCompileShader(shader)
            var compiled: GLint = 0
            glGetShaderiv(shader, GLenum(GL_COMPILE_STATUS), &compiled)
            guard compiled == GL_TRUE else {
                glDeleteShader(shader)
                return 0
            }
            return shader
        }

        private static let vertexSource = #"""
        #version 300 es
        precision highp float;
        void main() {
            vec2 positions[3] = vec2[3](vec2(-1.0, -1.0), vec2(3.0, -1.0), vec2(-1.0, 3.0));
            gl_Position = vec4(positions[gl_VertexID], 0.0, 1.0);
        }
        """#

        private static let fragmentSource = #"""
        #version 300 es
        precision highp float;
        uniform vec2 uResolution;
        uniform float uTime;
        uniform float uEnergy;
        uniform sampler2D uChannel0;
        out vec4 fragColor;

        float hash11(float value) {
            value = fract(value * 0.1031);
            value *= value + 33.33;
            value *= value + value;
            return fract(value);
        }

        float spectrumAt(float progress) {
            return texture(uChannel0, vec2(clamp(progress, 0.001, 0.999), 0.25)).r;
        }

        float waveformAt(float progress) {
            return texture(uChannel0, vec2(clamp(progress, 0.001, 0.999), 0.75)).r * 2.0 - 1.0;
        }

        void main() {
            const float TAU = 6.28318530718;
            vec2 resolution = max(uResolution, vec2(1.0));
            vec2 uv = (2.0 * gl_FragCoord.xy - resolution) / min(resolution.x, resolution.y);
            float radius = length(uv);
            float angle = atan(uv.y, uv.x);
            float around = fract(angle / TAU + 0.5);
            float mirrored = abs(around * 2.0 - 1.0);
            float frequency = pow(clamp(mirrored, 0.0, 1.0), 2.05) * 0.72;
            float fft = spectrumAt(frequency);
            float neighbour = max(spectrumAt(frequency + 0.004), spectrumAt(frequency - 0.004));
            fft = max(fft, neighbour * 0.88);
            float wave = waveformAt(around);
            float ripple = sin(angle * 96.0 + uTime * 1.8) * fft * 0.008;
            float targetRadius = 0.39 + fft * 0.25 + wave * (0.012 + fft * 0.025) + ripple;
            float distanceToRing = abs(radius - targetRadius);
            float pixel = 1.0 / min(resolution.x, resolution.y);
            float core = 1.0 - smoothstep(pixel * 0.7, pixel * 2.0, distanceToRing);
            float halo = 0.005 / (distanceToRing + 0.005);
            halo *= halo;

            vec3 phase = vec3(0.0, 0.34, 0.67);
            vec3 ringColor = 0.55 + 0.45 * cos(6.2831853 * (around + phase));
            ringColor = mix(vec3(0.12, 0.72, 1.0), ringColor, 0.62);
            ringColor *= 0.48 + fft * 1.75;
            float guideDistance = abs(radius - 0.39);
            float guide = 1.0 - smoothstep(pixel * 0.5, pixel * 1.5, guideDistance);
            float innerPulseDistance = abs(radius - (0.33 + uEnergy * 0.025));
            float innerPulse = 0.0025 / (innerPulseDistance + 0.0025);
            innerPulse *= innerPulse;
            float vignette = 1.0 - smoothstep(0.75, 1.45, radius);
            vec3 color = vec3(0.001, 0.003, 0.008);
            color += ringColor * (core * 1.45 + halo * (0.14 + fft * 0.78));
            color += vec3(0.18, 0.42, 0.56) * guide * 0.34;
            color += ringColor * innerPulse * uEnergy * 0.12;
            color *= vignette;
            float grain = hash11(gl_FragCoord.x + gl_FragCoord.y * resolution.x + floor(uTime * 60.0));
            color += (grain - 0.5) * 0.006;
            fragColor = vec4(max(color, vec3(0.0)), 1.0);
        }
        """#
    }
}
