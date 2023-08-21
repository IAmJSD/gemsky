module ApplicationHelper
    def inside_layout(layout = "application", &block)
        render inline: capture(&block), layout: "layouts/#{layout}"
    end

    def get_parents(item)
        parent = item['parent']
        parents = []
        while parent
            parents << parent
            parent = parent['parent']
        end
        parents.reverse
    end
end
