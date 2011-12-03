module Jekyll

  class ExtractTag < Liquid::Block

    def unknown_tag(name, content, tokens)
      if name == "after"
        @after = content.strip
      else
        if name == "before"
          @before = content.strip
        else
          super
        end
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
          source = File.readlines(@file)
          $first_line_index = 0
          until $first_line_index >= source.size or source[$first_line_index].include? @after do 
            $first_line_index += 1
          end
          $first_line_index += 1
          $last_line_index = $first_line_index
          until $last_line_index >= source.size or source[$last_line_index].include? @before do 
            $last_line_index += 1
          end
          $last_line_index -= 1
          if 0 < $first_line_index and $first_line_index <= $last_line_index and $last_line_index < source.size-1
            partial = Liquid::Template.parse(source[$first_line_index..$last_line_index].join("\n"))
          else
            return "Unable to determine which lines of '#{@file}' are between '#{@after}' and '#{@before}'"
          end
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
