# frozen_string_literal: true

class CharacterDecorator < ApplicationDecorator
  include RootResourceDecoratorCommon

  def name_link
    h.link_to local_name, h.character_path(self)
  end

  def db_header_title
    local_name
  end

  def name_with_series
    return local_name if series.blank?
    series_text = I18n.t("noun.series_with_name", series_name: series.decorate.local_name)
    "#{local_name} (#{series_text})"
  end

  def grid_description(cast)
    "CV: #{cast.person.decorate.name_link}"
  end

  def to_values
    model.class::DIFF_FIELDS.each_with_object({}) do |field, hash|
      hash[field] = send(field)
      hash
    end
  end

  def db_detail_link(options = {})
    name = options.delete(:name).presence || self.name
    path = h.edit_db_character_path(self)
    h.link_to name, path, options
  end
end
