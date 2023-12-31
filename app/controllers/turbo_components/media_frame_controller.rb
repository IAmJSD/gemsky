module TurboComponents
    class MediaFrameController < TurboComponentsController
        skip_before_action :user_must_authenticate!

        YOUTUBE_SHORT_PATH = /^\/([a-zA-Z0-9_-]{11})$/
        TWITCH_CHANNEL_PATH = /^\/([a-zA-Z0-9][\w]{2,24})$/
        TWITCH_VIDEO_PATH = /^\/videos\/([0-9]+)$/

        def skeet_media_frame
            # Get the URL.
            url = params[:url]

            # Try to parse the URL.
            begin
                url = URI.parse(url)
            rescue StandardError
                # Nope
                raise ActionController::RoutingError.new('Not Found')
            end

            # Make sure the URL is a valid scheme.
            unless %w[http https].include?(url.scheme)
                return render 'blank_media'
            end

            # Match on the host.
            case url.host
            when 'youtube.com', 'www.youtube.com'
                # Validate the path is /watch.
                return render 'blank_media' unless url.path == '/watch'

                # Parse the query.
                query = CGI.parse(url.query)

                # Return if v is not in the query.
                return render 'blank_media' unless query['v']

                # Set the first v as the video ID.
                @video_id = query['v'].first

                # Render the YouTube media.
                render 'youtube_media'
            when 'youtu.be', 'www.youtu.be'
                # Validate the path is a valid video ID.
                res = url.path.match(YOUTUBE_SHORT_PATH)
                return render 'blank_media' unless res

                # Set the video ID.
                @video_id = res[1]

                # Render the YouTube media.
                render 'youtube_media'
            when 'twitch.tv', 'www.twitch.tv'
                # Defines the query.
                query = {
                    parent: request.host,
                }

                # Match on the path.
                m = url.path.match(TWITCH_CHANNEL_PATH)
                if m
                    # Set the channel.
                    query[:channel] = m[1]
                else
                    # Match on the path.
                    m = url.path.match(TWITCH_VIDEO_PATH)
                    return render 'blank_media' unless m

                    # Set the video.
                    query[:video] = m[1]
                end

                # Build the Twitch URL.
                @embed_url = "https://player.twitch.tv/?#{query.to_query}"

                # Render the Twitch media.
                render 'twitch_media'
            when 'giphy.com', 'www.giphy.com'
                # Split the path by dashes and then get the last part.
                @gif_id = url.path.split('-').last

                # Get the giphy API key.
                api_key = ENV['GIPHY_API_KEY'] || Rails.application.credentials.giphy_api_key
                return render 'blank_media' if api_key.nil?

                # Make a request to the Giphy API.
                uri = "https://api.giphy.com/v1/gifs/#{CGI.escape(@gif_id)}?api_key=#{CGI.escape(api_key)}"
                res = Minigun::GET.new(uri).run
                return render 'blank_media' unless res.ok?

                # Parse the JSON.
                json = res.json
                @media_url = json[:data][:images][:original][:url]
                @giphy_url = json[:data][:url]
                @media_alt = json[:data][:title]

                # Render the Giphy media.
                render 'giphy_media'
            when 'tenor.com', 'www.tenor.com'
                # Visit the URL and do a bit of parsing.
                res = Minigun::GET.new(url).
                    header('User-Agent', 'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)').
                    header('Accept', 'text/html').
                    run

                # Return if the request failed.
                return render 'blank_media' unless res.ok?

                # Parse the HTML.
                begin
                    doc = Nokogiri::HTML(res.body)
                rescue StandardError
                    return render 'blank_media'
                end

                # Find the store-cache script and parse the JSON.
                begin
                    script = doc.css('script#store-cache').first
                    json = FastJsonparser.parse(script.content)
                rescue StandardError
                    return render 'blank_media'
                end

                # Get the media URL.
                begin
                    res = json[:gifs][:byId].values.
                        first[:results][0]
                    @media_url = res[:media][0][:tinygif][:url]
                    @media_alt = res[:content_description]
                    @tenor_url = url.to_s
                rescue StandardError
                    return render 'blank_media'
                end

                # Render the Tenor media.
                render 'tenor_media'
            else
                # Render the blank media.
                render 'blank_media'
            end
        end
    end
end
