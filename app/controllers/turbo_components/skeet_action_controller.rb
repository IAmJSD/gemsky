module TurboComponents
    class SkeetActionController < TurboComponentsController
        before_action :validate_did_permissions!

        def skeet_action
            # Switch on the action.
            case params[:skeet_action]
            when 'like'
                like_action
            when 'repost'
                repost_action
            else
                raise ActionController::RoutingError.new('Not Found')
            end
    
            # Get the post.
            begin
                @post = @bluesky_user.bluesky_client.get_post_thread(params[:post_uri])
            rescue BlueskyError
                # Raise a 404 if we can't find the post.
                raise ActiveRecord::RecordNotFound
            end
    
            # Write the user.
            @bluesky_user.save!
    
            # Render post/view.
            render 'post/view'
        end
    
        private
    
        def like_action
            # Check if we have a like cid.
            like_cid = params[:action_cid]
            if like_cid.nil?
                # Create the like.
                begin
                    @bluesky_user.bluesky_client.create_record({
                        collection: 'app.bsky.feed.like',
                        record: {
                            :'$type' => 'app.bsky.feed.like',
                            createdAt: Time.now.utc.iso8601,
                            subject: {
                                cid: params[:post_cid],
                                uri: params[:post_uri],
                            },
                        },
                        repo: params[:did],
                    })
                rescue BlueskyError => e
                    Rails.logger.info("Did not like: #{e.error}: #{e.message}")
                end
            else
                # Delete the like.
                begin
                    @bluesky_user.bluesky_client.delete_record({
                        collection: 'app.bsky.feed.like',
                        repo: params[:did],
                        rkey: like_cid,
                    })
                rescue BlueskyError => e
                    Rails.logger.info("Did not unlike: #{e.error}: #{e.message}")
                end
            end
        end
    
        def repost_action
            # Check if we have a repost cid.
            repost_cid = params[:action_cid]
            if repost_cid.nil?
                # Create the repost.
                begin
                    @bluesky_user.bluesky_client.create_record({
                        collection: 'app.bsky.feed.repost',
                        record: {
                            :'$type' => 'app.bsky.feed.repost',
                            createdAt: Time.now.utc.iso8601,
                            subject: {
                                cid: params[:post_cid],
                                uri: params[:post_uri],
                            },
                        },
                        repo: params[:did],
                    })
                rescue BlueskyError => e
                    Rails.logger.info("Did not repost: #{e.error}: #{e.message}")
                end
            else
                # Delete the repost.
                begin
                    @bluesky_user.bluesky_client.delete_record({
                        collection: 'app.bsky.feed.repost',
                        repo: params[:did],
                        rkey: repost_cid,
                    })
                rescue BlueskyError => e
                    Rails.logger.info("Did not unrepost: #{e.error}: #{e.message}")
                end
            end
        end    
    end
end
