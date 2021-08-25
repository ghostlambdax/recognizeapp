class ImageAttachmentUploader < AttachmentUploader
  before :process, :validate_against_svg
  
  ImproperFileFormat = Class.new(Exception)

  def validate_against_svg(file)
    filename = file.path
    format = MiniMagick::Image.new(filename).identify{|i| i.format("%m") }
    raise ImproperFileFormat, "SVG's are not allowed." if format.downcase == "svg" || file.content_type.match(/svg/)
  end  
end
