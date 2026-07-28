require "./spec_helper"

describe AsciicrystalMathematical do
  describe "VERSION" do
    it "has a version" do
      AsciicrystalMathematical::VERSION.should eq("0.3.5.3")
    end

    it "tracks upstream version" do
      AsciicrystalMathematical::UPSTREAM_VERSION.should eq("0.3.5")
    end
  end

  describe AsciicrystalMathematical::Renderer do
    describe ".block_delimiters" do
      it "returns latexmath delimiters" do
        open, close = AsciicrystalMathematical::Renderer.block_delimiters("latexmath")
        open.should eq("\\[")
        close.should eq("\\]")
      end

      it "returns asciimath delimiters" do
        open, close = AsciicrystalMathematical::Renderer.block_delimiters("asciimath")
        open.should eq("\\$")
        close.should eq("\\$")
      end
    end

    describe ".inline_delimiters" do
      it "returns latexmath delimiters" do
        open, close = AsciicrystalMathematical::Renderer.inline_delimiters("latexmath")
        open.should eq("\\(")
        close.should eq("\\)")
      end

      it "returns asciimath delimiters" do
        open, close = AsciicrystalMathematical::Renderer.inline_delimiters("asciimath")
        open.should eq("\\$")
        close.should eq("\\$")
      end
    end

    describe ".wrap_block" do
      it "wraps latexmath in display delimiters (client mode)" do
        result = AsciicrystalMathematical::Renderer.wrap_block("E = mc^2", "latexmath", "client")
        result.should eq("\\[E = mc^2\\]")
      end

      it "wraps asciimath in display delimiters (client mode)" do
        result = AsciicrystalMathematical::Renderer.wrap_block("E = mc^2", "asciimath", "client")
        result.should eq("\\$E = mc^2\\$")
      end

      it "does not double-wrap already delimited expressions" do
        result = AsciicrystalMathematical::Renderer.wrap_block("\\[E = mc^2\\]", "latexmath", "client")
        result.should eq("\\[E = mc^2\\]")
      end

      it "handles empty expressions" do
        result = AsciicrystalMathematical::Renderer.wrap_block("", "latexmath", "client")
        result.should eq("")
      end
    end

    describe ".wrap_inline" do
      it "wraps latexmath in inline delimiters (client mode)" do
        result = AsciicrystalMathematical::Renderer.wrap_inline("x^2", "latexmath", "client")
        result.should eq("\\(x^2\\)")
      end

      it "wraps asciimath in inline delimiters (client mode)" do
        result = AsciicrystalMathematical::Renderer.wrap_inline("x^2", "asciimath", "client")
        result.should eq("\\$x^2\\$")
      end

      it "does not double-wrap already delimited expressions" do
        result = AsciicrystalMathematical::Renderer.wrap_inline("\\(x^2\\)", "latexmath", "client")
        result.should eq("\\(x^2\\)")
      end
    end

    describe ".katex_css" do
      it "generates a CSS link with default version" do
        css = AsciicrystalMathematical::Renderer.katex_css
        css.should contain("katex@0.16.11")
        css.should contain("stylesheet")
      end

      it "generates a CSS link with custom version" do
        css = AsciicrystalMathematical::Renderer.katex_css("0.16.10")
        css.should contain("katex@0.16.10")
      end
    end

    describe ".katex_js" do
      it "generates script tags with default version" do
        js = AsciicrystalMathematical::Renderer.katex_js
        js.should contain("katex@0.16.11")
        js.should contain("auto-render")
        js.should contain("renderMathInElement")
      end

      it "generates script tags with custom version" do
        js = AsciicrystalMathematical::Renderer.katex_js("0.16.10")
        js.should contain("katex@0.16.10")
      end
    end

    describe ".mathjax_js" do
      it "generates MathJax configuration and script" do
        js = AsciicrystalMathematical::Renderer.mathjax_js
        js.should contain("MathJax")
        js.should contain("mathjax@3.2.2")
        js.should contain("tex-chtml")
      end

      it "generates script tags with custom version" do
        js = AsciicrystalMathematical::Renderer.mathjax_js("3.3.0")
        js.should contain("mathjax@3.3.0")
      end
    end
  end

  describe AsciicrystalMathematical::ExtensionGroup do
    it "registers the extension group globally" do
      groups = Asciicrystal::Extensions.groups
      groups.has_key?(:mathematical).should be_true
    end
  end

  describe AsciicrystalMathematical::MathHeadProcessor do
    it "generates KaTeX CSS by default" do
      doc = Asciicrystal.load("= Test\n:stem: latexmath\n\nHello")
      processor = AsciicrystalMathematical::MathHeadProcessor.new
      result = processor.process(doc)
      result.should contain("katex")
      result.should contain("stylesheet")
    end

    it "returns empty for MathJax renderer (no head CSS needed)" do
      doc = Asciicrystal.load("= Test\n:stem: latexmath\n:mathematical-renderer: mathjax\n\nHello")
      processor = AsciicrystalMathematical::MathHeadProcessor.new
      result = processor.process(doc)
      result.should eq("")
    end

    it "uses custom KaTeX version" do
      doc = Asciicrystal.load("= Test\n:stem: latexmath\n:katex-version: 0.16.10\n\nHello")
      processor = AsciicrystalMathematical::MathHeadProcessor.new
      result = processor.process(doc)
      result.should contain("katex@0.16.10")
    end
  end

  describe AsciicrystalMathematical::MathFooterProcessor do
    it "generates KaTeX JS by default in client mode" do
      doc = Asciicrystal.load("= Test\n:stem: latexmath\n\nHello")
      processor = AsciicrystalMathematical::MathFooterProcessor.new
      result = processor.process(doc)
      result.should contain("katex")
      result.should contain("auto-render")
    end

    it "generates MathJax JS when renderer is mathjax" do
      doc = Asciicrystal.load("= Test\n:stem: latexmath\n:mathematical-renderer: mathjax\n\nHello")
      processor = AsciicrystalMathematical::MathFooterProcessor.new
      result = processor.process(doc)
      result.should contain("MathJax")
      result.should contain("tex-chtml")
    end

    it "returns empty in server mode" do
      doc = Asciicrystal.load("= Test\n:stem: latexmath\n:mathematical-mode: server\n\nHello")
      processor = AsciicrystalMathematical::MathFooterProcessor.new
      result = processor.process(doc)
      result.should eq("")
    end

    it "uses custom MathJax version" do
      doc = Asciicrystal.load("= Test\n:stem: latexmath\n:mathematical-renderer: mathjax\n:mathjax-version: 3.3.0\n\nHello")
      processor = AsciicrystalMathematical::MathFooterProcessor.new
      result = processor.process(doc)
      result.should contain("mathjax@3.3.0")
    end
  end

  describe AsciicrystalMathematical::MathTreeProcessor do
    it "returns document unchanged in client mode" do
      doc = Asciicrystal.load("= Test\n:stem: latexmath\n\nHello")
      processor = AsciicrystalMathematical::MathTreeProcessor.new
      result = processor.process(doc)
      result.should eq(doc)
    end
  end
end
