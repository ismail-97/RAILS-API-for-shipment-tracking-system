class EditorsRepresenter
    def initialize(editors)
        @editors = editors   
    end  

    def as_json
        editors.map do |editor|
            {
                id: editor.id,
                name: editor.name,
                email: editor.email,
                super_editor: editor.super_editor,
            }  
        end
    end

    private

    attr_reader :editors
end