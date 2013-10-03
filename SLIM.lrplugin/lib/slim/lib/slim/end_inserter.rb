module Slim
  # In Slim you don't need to close any blocks:
  #
  #   - if Slim.awesome?
  #     | But of course it is!
  #
  # However, the parser is not smart enough (and that's a good thing) to
  # automatically insert end's where they are needed. Luckily, this filter
  # does *exactly* that (and it does it well!)
  #
  # @api private
  class EndInserter < Filter
    ELSE_REGEX = /^else|elsif|when\b/
    END_REGEX = /^end\b/

    # Handle multi expression `[:multi, *exps]`
    def on_multi(*exps)
      result = [:multi]
      # This variable is true if the previous line was
      # (1) a control code and (2) contained indented content.
      prev_indent = false

      exps.each do |exp|
        if control?(exp)
          raise 'Explicit end statements are forbidden' if exp[2] =~ END_REGEX

          # Two control code in a row. If this one is *not*
          # an else block, we should close the previous one.
          append_end(result) if prev_indent && exp[2] !~ ELSE_REGEX

          # Indent if the control code contains something.
          prev_indent = !empty_exp?(exp[3])
        elsif exp[0] != :newline && prev_indent
          # This is *not* a control code, so we should close the previous one.
          # Ignores newlines because they will be inserted after each line.
          append_end(result)
          prev_indent = false
        end

        result << compile!(exp)
      end

      # The last line can be a control code too.
      prev_indent ? append_end(result) : result
    end

    private

    # Appends an end.
    def append_end(result)
      result << [:block, 'end']
    end

    # Checks if an expression is a Slim control code.
    def control?(exp)
      exp[0] == :slim && exp[1] == :control
    end
  end
end
