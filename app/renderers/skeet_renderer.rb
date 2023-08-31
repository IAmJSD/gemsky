# frozen_string_literal: true

class SkeetRenderer
    CONTENT_WARNING = /(.*[ct]w: *.+?)(\n|$)/mi
    MANY_MULTIPLE_NEWLINES = /\n{5,}/m
    BOLD_TEXT = /\*\*([^\n*]+?)\*\*/
    ITALIC_TEXT = /\*([^\n]+?)\*/
    UNDERLINE_TEXT = /_([^\n]+?)_/
    STRIKETHROUGH_TEXT = /~~([^\n]+?)~~/

    ALLOWED_URL_SCHEMES = %w[http https mailto ftp].freeze
    TENOR_GIF_PATH = /^\/view\/.+/
    GIPHY_GIF_PATH = /^\/gifs\/(.+-)+.+$/
    YOUTUBE_SHORT_PATH = /^\/[a-zA-Z0-9_-]{11}$/
    YOUTUBE_VIDEO_ID = /^[a-zA-Z0-9_-]{11}$/
    TWITCH_PATH = /^(\/[a-zA-Z0-9][\w]{2,24})|(\/videos\/[0-9]+)$/

    def initialize(text_content, skeet_id, facets)
        @text_content = text_content
        @skeet_id = ERB::Util.html_escape(skeet_id)
        @facets = facets
    end

    def media_url
        @last_media
    end

    def render_with_sliced_cw
        # Try to match a content warning.
        match = CONTENT_WARNING.match(@text_content)
        return [render_inline, false] unless match

        # Just render the match with ... at the end.
        content = match[1] + '...'
        [SkeetRenderer.new(content, @skeet_id, @facets).render_inline, true]
    end

    def render_inline
        # Tokenize the text and handle facets.
        tokens = tokenize_facets(@text_content)

        # XSS escape the non-facet tokens.
        tokens = tokens.map do |token|
            if token.is_a?(FacetToken)
                token
            else
                ERB::Util.html_escape(token)
            end
        end

        # Handle formatting.
        handle_formatting(tokens)

        # Handle newlines.
        handle_newlines(tokens)

        # Return the tokens.
        tokens.join('').html_safe
    end

    def render(&block)
        # Handle content warnings.
        html, closing, text = handle_content_warnings

        # Append the body information to the HTML.
        html += '<div class="skeet-content">'

        # Tokenize the text and handle facets.
        tokens = tokenize_facets(text)

        # XSS escape the non-facet tokens.
        tokens = tokens.map do |token|
            if token.is_a?(FacetToken)
                token
            else
                ERB::Util.html_escape(token)
            end
        end

        # Handle formatting.
        handle_formatting(tokens)

        # Handle newlines.
        handle_newlines(tokens)

        # Close the div.
        html += tokens.join('') + '</div>'

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

    def handle_spooky_url(url)
        # Try to parse the URL.
        begin
            parsed = URI.parse(url)
        rescue StandardError
            # Nope
            return false, false
        end

        # Check if it is a safe URL scheme for the user to click.
        return false, false unless ALLOWED_URL_SCHEMES.include?(parsed.scheme)

        # Check if this is a tenor or giphy link.
        case parsed.host
        when 'tenor.com'
            is_media = parsed.path.match(TENOR_GIF_PATH)
        when 'giphy.com'
            is_media = parsed.path.match(GIPHY_GIF_PATH)
        when 'youtube.com', 'www.youtube.com'
            is_media = parsed.path == '/watch'
            if is_media
                # Parse the query.
                query = CGI.parse(parsed.query)

                # Check if v is in the query.
                v = query['v']
                if v
                    # Get the first v.
                    v = v.first

                    # Check if it is a valid video ID.
                    is_media = v.match(YOUTUBE_VIDEO_ID)
                else
                    # Not a video ID.
                    is_media = false
                end
            end
        when 'youtu.be', 'www.youtu.be'
            is_media = parsed.path.match(YOUTUBE_SHORT_PATH)
        when 'twitch.tv', 'www.twitch.tv'
            is_media = parsed.path.match(TWITCH_PATH)
        else
            is_media = false
        end

        # Return the parsed URL.
        [parsed, is_media]
    end

    def handle_formatting(tokens)
        tokens.each_with_index do |token, index|
            next unless token.is_a?(String)

            # Handle bold.
            token = token.gsub(BOLD_TEXT, '<b>\1</b>')

            # Handle italic.
            token = token.gsub(ITALIC_TEXT, '<i>\1</i>')

            # Handle underline.
            token = token.gsub(UNDERLINE_TEXT, '<u>\1</u>')

            # Handle strikethrough.
            token = token.gsub(STRIKETHROUGH_TEXT, '<s>\1</s>')

            # Set the token.
            tokens[index] = token
        end
    end

    def handle_newlines(tokens)
        tokens.each_with_index do |token, index|
            next unless token.is_a?(String)

            # Replace multiple newlines with a couple newlines.
            token = token.gsub(MANY_MULTIPLE_NEWLINES, '\n\n')

            # Replace newlines with brs.
            token = token.gsub(/\n/, '<br>')

            # Set the token.
            tokens[index] = token
        end
    end

    class FacetToken
        def initialize(html)
            @html = html
        end

        def to_s
            @html
        end
    end

    def tokenize_facets(text)
        # Defines the tokens.
        tokens = []

        # Go through each facet.
        last_end = 0
        text_ascii = text.dup.force_encoding('ASCII-8BIT')
        @facets.each do |facet|
            # Get the start/end indexes.
            start_index = facet[:index][:byteStart]
            end_index = facet[:index][:byteEnd]

            # Get everything between this start index and the last end and push it.
            between = text_ascii[last_end...start_index]
            tokens.push(between.force_encoding('UTF-8')) unless between.nil?

            # Set last end to this.
            last_end = end_index

            # Get the content for this.
            content = text_ascii[start_index...end_index].force_encoding('UTF-8')

            # Make the content XSS safe.
            safe_content = ERB::Util.html_escape(content)

            # Get the first feature.
            feature = facet[:features].first
            unless feature
                tokens.push(content)
                next
            end

            # Switch on the type.
            case feature[:$type]
            when 'app.bsky.richtext.facet#mention'
                url = "/profile/#{feature[:did]}"
                html = "<a target=\"_top\" href=\"#{ERB::Util.html_escape(url)}\">#{safe_content}</a>".html_safe
            when 'app.bsky.richtext.facet#link'
                url = feature[:uri]

                # Try to parse the link.
                parsed, is_media = handle_spooky_url(url)

                # If it was not parsed, just add as a token.
                unless parsed
                    tokens.push(content)
                    next
                end

                # Build the HTML element.
                html = "<a target=\"_blank\" href=\"#{ERB::Util.html_escape(url)}\">#{safe_content}</a>".html_safe

                # If it is media, store it.
                @last_media = url if is_media
            else
                tokens.push(content)
                next
            end

            # Push the HTML.
            tokens.push(FacetToken.new(html))
        end

        # Push the last bit of text.
        r = text_ascii[last_end..].force_encoding('UTF-8')
        tokens.push(r) unless r.nil?

        # Return the tokens.
        tokens
    end

    def handle_content_warnings
        # Try to match a content warning.
        match = CONTENT_WARNING.match(@text_content)
        return '', '', @text_content unless match

        # Get the facets in this content warning.
        cw_facets = @facets.select do |facet|
            facet[:index][:byteStart] < match[0].length
        end

        # Get the content warning text.
        sanitized = SkeetRenderer.new(match[1], @skeet_id, cw_facets).render_inline

        # Remove any facets that are in the content warning and reallign them to the start of the text.
        @facets = @facets.select do |facet|
            return false unless facet[:index][:byteStart] > match[0].length
            facet[:index][:byteStart] -= match[0].length
            facet[:index][:byteEnd] -= match[0].length
            true
        end

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
