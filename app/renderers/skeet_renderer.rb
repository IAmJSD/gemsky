# frozen_string_literal: true

class GIFURLParser
    def initialize(url)
        @url = url
    end

    def parse
        # TODO
    end
end

class SkeetRenderer
    CONTENT_WARNING = /^([ct]w: *.+)\n/mi
    SHOULD_TRUNCATE = /^(.{20}).+/
    MANY_MULTIPLE_NEWLINES = /\n{5,}/m
    BOLD_TEXT = /\*\*[^\n]+\*\*/
    ITALIC_TEXT = /\*[^\n]+\*/
    UNDERLINE_TEXT = /_[^\n]+_/
    STRIKETHROUGH_TEXT = /~~[^\n]+~~/

    ALLOWED_URL_SCHEMES = %w[http https mailto ftp].freeze
    TENOR_GIF_PATH = /^\/view\/.+/
    GIPHY_GIF_PATH = /^\/gifs\/.+/
    GIPHY_MEDIA_GIF_PATH = /^\/media\/.+/

    def initialize(text_content, skeet_id)
        @text_content = text_content
        @skeet_id = ERB::Util.html_escape(skeet_id)
    end

    def gif
        return nil unless @last_gif
        GIFURLParser.new(@last_gif).parse
    end

    def render(&block)
        # Handle content warnings.
        html, closing, text = handle_content_warnings

        # Parse the text to HTML first before we do anything else.
        content_html = ERB::Util.html_escape(text)

        # Append <p> to the HTML.
        html += '<p>'

        # Handle links.
        content_html, no_mutation_ranges = handle_links(content_html)

        # Handle formatting.
        content_html = handle_formatting(content_html, no_mutation_ranges)

        # Handle newlines.
        content_html = handle_newlines(content_html)

        # Close the paragraph.
        html += content_html + '</p>'

        # Call the block with the GIF result.
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
            res << [c, $~.offset(0)[0]]
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
        start_fragment += ":#{parsed.port}" if parsed.port

        # Get the truncatable fragment.
        truncatable_fragment = parsed.path
        truncatable_fragment += "?#{parsed.query}" if parsed.query

        # Check if this is a tenor or giphy link.
        case parsed.host
        when 'tenor.com'
            is_gif = parsed.path.match(TENOR_GIF_PATH)
        when 'media.giphy.com'
            is_gif = parsed.path.match(GIPHY_MEDIA_GIF_PATH)
        when 'giphy.com'
            is_gif = parsed.path.match(GIPHY_GIF_PATH)
        else
            is_gif = false
        end

        # Return the parsed URL, the start fragment, the truncatable fragment, and the GIF status.
        [parsed, start_fragment, truncatable_fragment, is_gif]
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
            parsed, start_fragment, truncatable_fragment, is_gif = handle_spooky_url(link)

            # If it was not parsed, add the link start and end to the no mutation ranges.
            unless parsed
                no_mutation_ranges << [index, index + link.length]
                next
            end

            # Truncate the fragment if it is too long.
            truncatable_fragment = truncatable_fragment.gsub(SHOULD_TRUNCATE, '\1…')

            # Build the HTML element.
            html = "<a href=\"#{link}\">#{start_fragment}#{truncatable_fragment}</a>"

            # Replace the link with the HTML element without mutating the string.
            content_html = content_html[0...index] + html + content_html[index + link.length..-1]

            # Add the difference between the link and the a tag to every item in the array after this one.
            difference = html.length - link.length
            links[array_index + 1..-1].each do |link_b|
                link_b[1] += difference
            end

            # Add to the no mutation ranges.
            no_mutation_ranges << [index, index + html.length]

            # If this is a GIF, set @last_gif to this.
            @last_gif = link if is_gif
        end

        # Return the content HTML and the no mutation ranges.
        [content_html, no_mutation_ranges]
    end

    def run_parse(content_html, regex, part_len, tag, no_mutation_ranges)
        # Scan the content HTML for the regex.
        html_results = scan_with_index(content_html, regex)

        # Loop through the results.
        html_results.each do |html_result|
            # Get the HTML and the index.
            html, index = html_result

            # Check if the index is in a no mutation range.
            next if no_mutation_ranges.any? do |no_mutation_range|
                index >= no_mutation_range[0] && index < no_mutation_range[1]
            end

            # Replace the HTML with it wrapped in the tag.
            tagged_html = "<#{tag}>#{html[part_len..-part_len]}</#{tag}>"

            # Replace the HTML without mutating the string.
            content_html = content_html[0...index] + tagged_html + content_html[index + tagged_html.length..-1]

            # Add the difference between the HTML and the tag to every item in the array after this one.
            difference = tagged_html.length - html.length
            html_results.each do |html_result_b|
                html_result_b[1] += difference
            end

            # Add the difference to every item in the no mutation ranges after this one.
            no_mutation_ranges.each do |no_mutation_range|
                no_mutation_range[0] += difference if no_mutation_range[0] > index
                no_mutation_range[1] += difference if no_mutation_range[1] > index
            end
        end

        # Return the content HTML.
        content_html
    end

    def handle_formatting(content_html, no_mutation_ranges)
        # Call the above method a bunch of times.
        content_html = run_parse(content_html, BOLD_TEXT, 2, 'strong', no_mutation_ranges)
        content_html = run_parse(content_html, ITALIC_TEXT, 1, 'em', no_mutation_ranges)
        content_html = run_parse(content_html, UNDERLINE_TEXT, 1, 'u', no_mutation_ranges)
        run_parse(content_html, STRIKETHROUGH_TEXT, 2, 's', no_mutation_ranges)
    end

    def handle_newlines(content_html)
        # Replace multiple newlines with a couple newlines.
        content_html = content_html.gsub(MANY_MULTIPLE_NEWLINES, '\n\n')

        # Replace newlines with new paragraphs.
        content_html = content_html.gsub(/\n/, '</p><p>')

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
    <p>#{sanitized} <button
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
<div style=\"display: none;\" id=\"#{@skeet_id}\" data-content-warning-target=\"content\">"
        return html, closing, match.post_match
    end
end
