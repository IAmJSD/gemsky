class SkeetRenderer
    CONTENT_WARNING = /^([ct]w: *.+)\n/mi

    def initialize(text_content, skeet_id)
        @text_content = text_content
        @skeet_id = ERB::Util.html_escape(skeet_id)
    end

    def render
        # Handle content warnings.
        html, closing, text = handle_content_warnings

        # TODO

        # Add the closing onto the HTML.
        html += closing

        # Mark this HTML as XSS safe.
        html.html_safe
    end

    private

    def handle_content_warnings
        # Try to match a content warning.
        match = CONTENT_WARNING.match(@text_content)
        return '', '', @text_content.clone unless match

        # Get a santized version of the content warning.
        sanitized = ERB::Util.html_escape(match[1])

        # Get the HTML for the content warning.
        closing = '</div></div>'
        html = "<div data-controller=\"content-warning\">
<p>#{sanitized} <form data-action=\"submit->content-warning#toggle\"><button
    aria-controls=\"#{@skeet_id}_content\"
    aria-expanded=\"false\"
    aria-haspopup=\"true\"
    type=\"button\"
    data-content-warning-target=\"button\"
>
    Show Content
</button></form></p>
<div style=\"display: none;\" id=\"#{@skeet_id}\" data-content-warning-target=\"content\">"
        return html, closing, match.post_match
    end
end
