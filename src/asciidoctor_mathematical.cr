require "crystal-asciidoctor"
require "./asciidoctor_mathematical/renderer"
require "./asciidoctor_mathematical/extension"

module AsciidoctorMathematical
  VERSION = "0.1.0"

  # Ruby gem version this is inspired by (different approach: KaTeX/MathJax
  # instead of Mathematical/lasem C library).
  UPSTREAM_VERSION = "0.3.5"
end
