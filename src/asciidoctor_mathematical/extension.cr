module AsciicrystalMathematical
  # DocinfoProcessor that injects KaTeX or MathJax CSS into <head>.
  class MathHeadProcessor < Asciicrystal::Extensions::DocinfoProcessor
    def initialize
      super({"location" => :head} of String => String | Bool | Int32 | Array(String) | Set(Symbol) | Symbol)
    end

    def process(document : Asciicrystal::Document) : String
      renderer = document.attr("mathematical-renderer", "katex") || "katex"
      version = case renderer
                when "mathjax"
                  # MathJax does not need head CSS
                  return ""
                else
                  document.attr("katex-version", Renderer::DEFAULT_KATEX_VERSION) || Renderer::DEFAULT_KATEX_VERSION
                end
      Renderer.katex_css(version)
    end
  end

  # DocinfoProcessor that injects KaTeX or MathJax JS into the footer.
  class MathFooterProcessor < Asciicrystal::Extensions::DocinfoProcessor
    def initialize
      super({"location" => :footer} of String => String | Bool | Int32 | Array(String) | Set(Symbol) | Symbol)
    end

    def process(document : Asciicrystal::Document) : String
      mode = document.attr("mathematical-mode", "client") || "client"
      # In server mode, JS injection is not needed (math is pre-rendered)
      return "" if mode == "server"

      renderer = document.attr("mathematical-renderer", "katex") || "katex"
      case renderer
      when "mathjax"
        version = document.attr("mathjax-version", Renderer::DEFAULT_MATHJAX_VERSION) || Renderer::DEFAULT_MATHJAX_VERSION
        Renderer.mathjax_js(version)
      else
        version = document.attr("katex-version", Renderer::DEFAULT_KATEX_VERSION) || Renderer::DEFAULT_KATEX_VERSION
        Renderer.katex_js(version)
      end
    end
  end

  # TreeProcessor that processes STEM blocks and inlines after parsing.
  #
  # In server mode, it replaces STEM content with pre-rendered HTML.
  # In client mode, the content is left as-is (the injected JS handles it).
  class MathTreeProcessor < Asciicrystal::Extensions::TreeProcessor
    def process(document : Asciicrystal::Document) : Asciicrystal::Document?
      mode = document.attr("mathematical-mode", "client") || "client"
      # In client mode, the browser-side renderer handles everything.
      # We only need to intervene in server mode.
      return document unless mode == "server"

      process_blocks(document)
      document
    end

    private def process_blocks(node : Asciicrystal::AbstractBlock) : Nil
      node.blocks.each do |block|
        if block.context == :stem && block.is_a?(Asciicrystal::Block)
          style = block.style || "latexmath"
          content = block.content.to_s
          rendered = Renderer.wrap_block(content, style, "server")
          # Replace the block content with the rendered HTML
          block.lines = [rendered]
        end
        process_blocks(block) if block.blocks?
      end
    end
  end

  # Extension group that registers all mathematical processors.
  #
  # Usage:
  #   Asciicrystal::Extensions.register(:mathematical, AsciicrystalMathematical::ExtensionGroup)
  #
  # Or automatically when requiring the library:
  #   require "asciidoctor_mathematical"
  class ExtensionGroup < Asciicrystal::Extensions::Group
    def activate(registry : Asciicrystal::Extensions::Registry) : Nil
      registry.docinfo_processor(MathHeadProcessor.new)
      registry.docinfo_processor(MathFooterProcessor.new)
      registry.tree_processor(MathTreeProcessor.new)
    end
  end

  # Auto-register the extension group globally.
  Asciicrystal::Extensions.register(:mathematical, ExtensionGroup)
end
