module Jekyll

  class ExtractTag < Liquid::Block

    def unknown_tag(name, content, tokens)
      case name
      when "after"
        @after = content.strip
      when "before"
        @before = content.strip
      else
        super
      end
    end

    def initialize(tag_name, file, tokens)
      super
      @file = file.strip
    end

    def render(context)
      includes_dir = File.join(context.registers[:site].source, '_includes')

      if File.symlink?(includes_dir)
        return "Includes directory '#{includes_dir}' cannot be a symlink"
      end

      if @file !~ /^[a-zA-Z0-9_\/\.-]+$/ || @file =~ /\.\// || @file =~ /\/\./
        return "Include file '#{@file}' contains invalid characters or sequences"
      end

      Dir.chdir(includes_dir) do
        choices = Dir['**/*'].reject { |x| File.symlink?(x) }
        if @after.nil?
          return "{% after _line_ %} missing in {% extract %} block."
        end
        if @before.nil?
          return "{% before _line_ %} missing in {% extract %} block."
        end
        if choices.include?(@file)
          source = File.read(@file)
          matchdata = source.match /#{Regexp.escape(@after)}[^\n]*\n(.*)\n.*#{Regexp.escape(@before)}/m
          if matchdata.nil? or matchdata.size < 2
            return "Unable to determine which lines of '#{@file}' are between '#{@after}' and '#{@before}'"
          end
          source = matchdata[1]
          partial = Liquid::Template.parse(source)
          context.stack do
            partial.render(context)
          end
        else
          "Included file '#{@file}' not found in _includes directory"
        end
      end
    end
  end

end

Liquid::Template.register_tag('extract', Jekyll::ExtractTag)
