# frozen_string_literal: true

class SkeetPostContentsComponent < ViewComponent::Base
    def initialize(skeet_body:)
      @skeet_body = skeet_body
    end
  
    def skeet_hash
      return @skeet_hash unless @skeet_hash.nil?
      @skeet_hash = Digest::SHA256.hexdigest(@skeet_body['cid'])
    end
  
    def make_media_url_frame(media_url)
      encoded_media_url = ERB::Util.url_encode(media_url)
      "/components/skeet_media_frame/skeet-media-#{skeet_hash}/#{encoded_media_url}"
    end
  end
  