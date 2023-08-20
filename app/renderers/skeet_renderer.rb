# frozen_string_literal: true

class SkeetRenderer
    CONTENT_WARNING = /^([ct]w: *.+?)\n/mi
    SHOULD_TRUNCATE = /^(.{20}).+/
    MANY_MULTIPLE_NEWLINES = /\n{5,}/m
    BOLD_TEXT = /\*\*([^\n*]+?)\*\*/
    ITALIC_TEXT = /\*([^\n]+?)\*/
    UNDERLINE_TEXT = /_([^\n]+?)_/
    STRIKETHROUGH_TEXT = /~~([^\n]+?)~~/

    ALLOWED_URL_SCHEMES = %w[http https mailto ftp].freeze
    TENOR_GIF_PATH = /^\/view\/.+/
    GIPHY_GIF_PATH = /^\/gifs\/.+/
    GIPHY_MEDIA_GIF_PATH = /^\/media\/.+/

    def initialize(text_content, skeet_id)
        @text_content = text_content
        @skeet_id = ERB::Util.html_escape(skeet_id)
    end

    def media_url
        return nil unless @last_media
        @last_media
    end

    def render(&block)
        # Handle content warnings.
        html, closing, text = handle_content_warnings

        # Parse the text to HTML first before we do anything else.
        content_html = ERB::Util.html_escape(text)

        # Append the body information to the HTML.
        html += '<div class="skeet-content">'

        # Handle links.
        content_html, no_mutation_ranges = handle_links(content_html)

        # Handle formatting.
        content_html = handle_formatting(content_html, no_mutation_ranges)

        # Handle newlines.
        content_html = handle_newlines(content_html)

        # Close the div.
        html += content_html + '</div>'

        # Call the block with ourselves.
        res = block.call(self) if block

        # If the block returned something, add it to the HTML.
        html += res if res

        # Add the closing onto the HTML.
        html += closing

        # Mark this HTML as XSS safe.
        html.html_safe
    end

    private

    def scan_with_index(string, regex)
        res = []
        string.scan(regex) do |c|
            res << [$&, $~.offset(0)[0]]
        end
        res
    end

    def handle_spooky_url(url)
        # Try to parse the URL.
        begin
            parsed = URI.parse(url)
        rescue StandardError
            # Nope
            return false, '', '', false
        end

        # Check if it is a safe URL scheme for the user to click.
        return false, '', '', false unless ALLOWED_URL_SCHEMES.include?(parsed.scheme)

        # Get the start fragment.
        start_fragment = "#{parsed.scheme}://#{parsed.host}"

        # Get the truncatable fragment.
        truncatable_fragment = parsed.path
        truncatable_fragment += "?#{parsed.query}" if parsed.query

        # Check if this is a tenor or giphy link.
        case parsed.host
        when 'tenor.com'
            is_media = parsed.path.match(TENOR_GIF_PATH)
        when 'media.giphy.com'
            is_media = parsed.path.match(GIPHY_MEDIA_GIF_PATH)
        when 'giphy.com'
            is_media = parsed.path.match(GIPHY_GIF_PATH)
        else
            is_media = false
        end

        # Return the parsed URL, the start fragment, the truncatable fragment, and the media status.
        [parsed, start_fragment, truncatable_fragment, is_media]
    end

    def handle_links(content_html)
        # Find all the links.
        links = scan_with_index(content_html, URI.regexp)

        # Defines the array for no mutation ranges.
        no_mutation_ranges = []

        # Loop through the links.
        links.each_with_index do |link_a, array_index|
            # Get the link and the index.
            link, index = link_a

            # Try to parse the link.
            parsed, start_fragment, truncatable_fragment, is_media = handle_spooky_url(link)

            # If it was not parsed, add the link start and end to the no mutation ranges.
            unless parsed
                no_mutation_ranges << [index, index + link.length]
                next
            end

            # Truncate the fragment if it is too long.
            truncatable_fragment = truncatable_fragment.gsub(SHOULD_TRUNCATE, '\1…')

            # Build the HTML element.
            html = "<a target=\"_blank\" href=\"#{link}\">#{start_fragment}#{truncatable_fragment}</a>".html_safe

            # Replace the link with the HTML element without mutating the string.
            content_html = content_html[0...index] + html + content_html[index + link.length..-1]

            # Add the difference between the link and the a tag to every item in the array after this one.
            difference = html.length - link.length
            links[array_index + 1..-1].each do |link_b|
                link_b[1] += difference
            end

            # Add to the no mutation ranges.
            no_mutation_ranges << [index, index + html.length]

            # If this is media, set @last_mmedia to this.
            @last_media = link if is_media
        end

        # Return the content HTML and the no mutation ranges.
        [content_html, no_mutation_ranges]
    end

    class NoFormatting
        def initialize(text)
            @text = text
        end

        def to_s
            @text
        end
    end

    def handle_formatting(content_html, no_mutation_ranges)
        # Split the content HTML into an array of bits. Put
        # the bits that should not be formatted into the array with
        # the NoFormatting class.
        bits = []
        last_end = 0
        no_mutation_ranges.each_with_index do |range, index|
            # Get the start and end of the range.
            start, end_ = range

            # Get the text.
            text = content_html[start...end_]

            # Add the in-between text to bits.
            inbetween = content_html[last_end...start]
            bits << inbetween unless inbetween.empty?

            # Add the text to bits.
            bits << NoFormatting.new(text) unless text.empty?

            # Set last end to the end of the range.
            last_end = end_
        end

        # Set the remainder to everything after the last range.
        bits << content_html[last_end..-1]

        # Go through the bits.
        bits.each_with_index do |bit, index|
            next if bit.is_a? NoFormatting

            # Handle bold.
            bit = bit.gsub(BOLD_TEXT, '<b>\1</b>')

            # Handle italic.
            bit = bit.gsub(ITALIC_TEXT, '<i>\1</i>')

            # Handle underline.
            bit = bit.gsub(UNDERLINE_TEXT, '<u>\1</u>')

            # Handle strikethrough.
            bit = bit.gsub(STRIKETHROUGH_TEXT, '<s>\1</s>')

            # Replace the bit.
            bits[index] = bit
        end

        # Transform the bits into a string.
        bits = bits.map(&:to_s).join

        # Return the bits.
        bits.html_safe
    end

    def handle_newlines(content_html)
        # Remove newlines from the start.
        content_html = content_html.gsub(/\A\n+/, '')

        # Replace multiple newlines with a couple newlines.
        content_html = content_html.gsub(MANY_MULTIPLE_NEWLINES, '\n\n')

        # Replace newlines with brs.
        content_html = content_html.gsub(/\n/, '<br>')

        # Return the content HTML.
        content_html
    end

    def handle_content_warnings
        # Try to match a content warning.
        match = CONTENT_WARNING.match(@text_content)
        return '', '', @text_content unless match

        # Get a santized version of the content warning.
        sanitized = ERB::Util.html_escape(match[1])

        # Get the HTML for the content warning.
        closing = '</div></div>'
        html = "<div data-controller=\"content-warning\">
<form data-action=\"submit->content-warning#toggle\">
    <p class=\"skeet-content\">#{sanitized} <button
        style=\"background-color: white; border: 1px solid black; border-radius: 5px; margin-left: 0.1rem; padding: 0.3rem; color: black;\"
        aria-controls=\"#{@skeet_id}_content\"
        aria-expanded=\"false\"
        aria-haspopup=\"true\"
        type=\"submit\"
        data-content-warning-target=\"button\"
    >
        Show Content
    </button></p>
</form>
<div style=\"display: none; margin-top: 1rem;\" id=\"#{@skeet_id}\" data-content-warning-target=\"content\">"
        return html, closing, match.post_match
    end
end
