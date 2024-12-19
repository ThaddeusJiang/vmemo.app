defmodule Vmemo.Ts.Migration20241219 do

  alias SmallSdk.Typesense

  def define do
    photos_schema = %{
      "fields" => [
        %{"name" => "note_ids", "type" => "string[]", "optional" => true, "facet" => true}
      ]
    }

    Typesense.update_collection("photos", photos_schema)

    notes_schema = %{
      "name" => "notes",
      "fields" => [
        %{"name" => "text", "type" => "string"},
        %{"name" => "photo_ids", "type" => "string[]", "optional" => true, "facet" => true},
        %{"name" => "inserted_at", "type" => "int64"},
        %{"name" => "updated_at", "type" => "int64"},
        %{"name" => "belongs_to", "type" => "string", "facet" => true}
      ],
      "default_sorting_field" => "inserted_at"
    }

    Typesense.create_collection(notes_schema)
  end


end

Vmemo.Ts.Migration20241219.define()
