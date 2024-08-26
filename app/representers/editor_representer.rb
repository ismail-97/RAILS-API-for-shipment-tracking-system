class EditorRepresenter
    def initialize(editor)
        @editor = editor
    end  

    def as_json
        {
            id: @editor.id,
            name: @editor.name,
            email: @editor.email,
            super_editor: @editor.super_editor,
        }  
    end

    private

    attr_reader :editor
end