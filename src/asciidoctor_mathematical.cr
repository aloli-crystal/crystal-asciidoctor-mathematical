require "asciicrystal"
require "./asciidoctor_mathematical/renderer"
require "./asciidoctor_mathematical/extension"

module AsciicrystalMathematical
  # Lue au compile-time depuis `shard.yml` via le macro `read_file`.
  # Cf. note mémoire `feedback_shard_version_macro.md` (mémoire ALOLI).
  VERSION = {{
              (read_file("#{__DIR__}/../shard.yml")
                .lines
                .find(&.starts_with?("version:")) || "version: 0.0.0")
                .gsub(/^version:\s*/, "")
                .chomp
            }}

  # Ruby gem version this is inspired by (different approach: KaTeX/MathJax
  # instead of Mathematical/lasem C library).
  UPSTREAM_VERSION = "0.3.5"
end
