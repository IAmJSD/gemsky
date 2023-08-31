module ApplicationHelper
    def inside_layout(layout = "application", &block)
        render inline: capture(&block), layout: "layouts/#{layout}"
    end

    def get_parents(item)
        parent = item[:parent]
        parents = []
        while parent
            parents << parent
            parent = parent[:parent]
        end
        parents.reverse
    end

    def make_profile_link(did)
        authed_did = get_authed_did
        return "/profiles/#{did}" unless authed_did

        params = {
            authed_did: authed_did,
        }
        "/profiles/#{did}?#{params.to_query}"
    end

    def make_post_link(did, post_id)
        authed_did = get_authed_did
        return "/post/#{did}/#{post_id}" unless authed_did

        params = {
            authed_did: authed_did,
        }
        "/post/#{did}/#{post_id}?#{params.to_query}"
    end

    private

    def get_authed_did
        return nil if user.nil? || user.linked_bluesky_users.length == 1
        @bluesky_user.did
    end
end
