module AsciidoctorMathematical
  # Renderer handles STEM expression rendering, either server-side via
  # the `katex` CLI or by preparing content for client-side rendering.
  module Renderer
    DEFAULT_KATEX_VERSION  = "0.16.11"
    DEFAULT_MATHJAX_VERSION = "3.2.2"

    # Render a math expression server-side using the `katex` CLI.
    #
    # Returns the rendered HTML string, or nil if the CLI is not available
    # or rendering fails.
    def self.render_server_katex(expression : String, display_mode : Bool = false) : String?
      return nil if expression.strip.empty?

      args = ["katex"]
      args << "--display-mode" if display_mode
      args << "--trust"

      process = Process.new(
        command: args[0],
        args: args[1..],
        input: Process::Redirect::Pipe,
        output: Process::Redirect::Pipe,
        error: Process::Redirect::Pipe
      )

      process.input.print(expression)
      process.input.close

      output = process.output.gets_to_end
      error = process.error.gets_to_end
      status = process.wait

      if status.success?
        output.strip
      else
        nil
      end
    rescue ex : IO::Error | File::NotFoundError
      # katex CLI not available
      nil
    end

    # Check whether the `katex` CLI is available on the system.
    def self.katex_cli_available? : Bool
      process = Process.new(
        command: "katex",
        args: ["--version"],
        output: Process::Redirect::Pipe,
        error: Process::Redirect::Pipe
      )
      process.output.gets_to_end
      process.error.gets_to_end
      process.wait.success?
    rescue ex : IO::Error | File::NotFoundError
      false
    end

    # Generate the KaTeX CSS link tag for the document head.
    def self.katex_css(version : String = DEFAULT_KATEX_VERSION) : String
      %(<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/katex@#{version}/dist/katex.min.css" integrity="sha384-n8MVd4RsNIU0tQ+jFMVQXCBMpdJBWu6+Mp1OS2RXMnLPMaeIdiskP0d+TP7/Y8o3" crossorigin="anonymous">)
    end

    # Generate the KaTeX JS script tags for the document footer.
    #
    # Includes the auto-render extension so that `\(...\)` and `\[...\]`
    # delimiters are processed automatically.
    def self.katex_js(version : String = DEFAULT_KATEX_VERSION) : String
      String.build do |io|
        io << %(<script defer src="https://cdn.jsdelivr.net/npm/katex@#{version}/dist/katex.min.js" crossorigin="anonymous"></script>\n)
        io << %(<script defer src="https://cdn.jsdelivr.net/npm/katex@#{version}/dist/contrib/auto-render.min.js" crossorigin="anonymous")
        io << %( onload="renderMathInElement(document.body, {delimiters: [)
        io << %({left: '\\\\\\\\[', right: '\\\\\\\\]', display: true},)
        io << %({left: '\\\\\\\\(', right: '\\\\\\\\)', display: false},)
        io << %({left: '\\\\$', right: '\\\\$', display: false})
        io << %(]});"></script>)
      end
    end

    # Generate the MathJax configuration and script tag for the document footer.
    def self.mathjax_js(version : String = DEFAULT_MATHJAX_VERSION) : String
      String.build do |io|
        io << "<script>\n"
        io << "MathJax = {\n"
        io << "  tex: {\n"
        io << "    inlineMath: [['\\\\(', '\\\\)'], ['\\$', '\\$']],\n"
        io << "    displayMath: [['\\\\[', '\\\\]']]\n"
        io << "  }\n"
        io << "};\n"
        io << "</script>\n"
        io << %(<script src="https://cdn.jsdelivr.net/npm/mathjax@#{version}/es5/tex-chtml.js" async></script>)
      end
    end

    # Wrap a STEM expression as a block (display math).
    #
    # In server mode with KaTeX, the expression is pre-rendered.
    # In client mode, the raw expression is wrapped in delimiters for
    # the browser-side renderer.
    def self.wrap_block(expression : String, style : String, mode : String) : String
      if mode == "server"
        rendered = render_server_katex(expression, display_mode: true)
        if rendered
          return rendered
        end
        # Fall back to client mode if server rendering fails
      end

      # Client mode: wrap in appropriate delimiters
      delimiters = block_delimiters(style)
      equation = expression.strip
      unless equation.empty? || (equation.starts_with?(delimiters[0]) && equation.ends_with?(delimiters[1]))
        equation = "#{delimiters[0]}#{equation}#{delimiters[1]}"
      end
      equation
    end

    # Wrap a STEM expression as inline math.
    #
    # In server mode with KaTeX, the expression is pre-rendered.
    # In client mode, the raw expression is wrapped in delimiters.
    def self.wrap_inline(expression : String, style : String, mode : String) : String
      if mode == "server"
        rendered = render_server_katex(expression, display_mode: false)
        if rendered
          return rendered
        end
        # Fall back to client mode if server rendering fails
      end

      # Client mode: wrap in appropriate delimiters
      delimiters = inline_delimiters(style)
      equation = expression.strip
      unless equation.empty? || (equation.starts_with?(delimiters[0]) && equation.ends_with?(delimiters[1]))
        equation = "#{delimiters[0]}#{equation}#{delimiters[1]}"
      end
      equation
    end

    # Returns the display-math delimiters for the given style.
    def self.block_delimiters(style : String) : Tuple(String, String)
      case style
      when "latexmath"
        {"\\[", "\\]"}
      else # asciimath
        {"\\$", "\\$"}
      end
    end

    # Returns the inline-math delimiters for the given style.
    def self.inline_delimiters(style : String) : Tuple(String, String)
      case style
      when "latexmath"
        {"\\(", "\\)"}
      else # asciimath
        {"\\$", "\\$"}
      end
    end
  end
end
