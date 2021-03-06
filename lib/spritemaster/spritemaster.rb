require 'json'
require 'xmlsimple'

module Spritemaster
  class Spritemaster
    def initialize(options = {})
      @prefix = options[:prefix] || 'icon'
      @dst    = ""
      @src    = get_filename(options[:src], 'plist')
      @img    = get_filename(options[:img], 'png') || @src.gsub('.plist','.png')
      @format = (get_extension @src)[0]
      @master_keys = []
    end

    def generate_css
      contents     = get_src_contents(@src)
      if @format == 'json'
        keys         = contents['plist']['dict']['dict'][0]['key']
        items        = contents['plist']['dict']['dict'][0]['dict']
      elsif @format == 'plist'
        keys = contents['dict'][0]['dict'][0]['key']
        items = contents['dict'][0]['dict'][0]['dict']
      else
        write_fatal_error("Invalid Format of image (-i --image)")
      end
      css          = ''

      # Start css file.
      css << '[class^="' << @prefix << '-"] {
        background-image: url("' << @img << '");
        background-position: 0 0;
        background-repeat: no-repeat;
        display: inline-block;
        width: 0;
        height: 0;
        vertical-align: text-top;
      }'

      # Loop through each key.
      keys.each do |key|
        # Take the key and remove prefixes to the file name
        name = key.gsub(/^\w*_[0-9]*_/i, "").gsub(/.png$/, "").gsub('_', '-').gsub('@2x', '-x2')
        # Push into master keys file for parsing down below
        @master_keys.push name
      end

      # Loop through items to retrieve coordinates and dimensions.
      items.each_with_index do |item, index|
        data = item["string"].last.scan(/(?:[0-9]+,.[0-9]+)/)

        # Get coordinates and dimensions from data
        coords = data[0].gsub(" ", "").split(",")
        dimensions = data[1].gsub(" ", "").split(",")
        key = @master_keys[index]

        # Build css rules
        # .[prefix]-[name] { background-position: -14px -14px; width: 24px; height: 24px; }
        css << "\n." << @prefix << "-" << key << "{"
        css << " background-position: -" << coords[0] << "px -" << coords[1] << "px; "
        css << "width: " << dimensions[0] << "px; "
        css << "height: " << dimensions[1] << "px; "
        css << "}"
      end

      # Write css file
      @dst = @prefix + '-sprites.css'
      file = File.open(@dst, 'w') { |f| f.write(css) }

      if file > 0
        puts "Generated css file: #{@dst}"
      else
        puts "Failed to generate css file!"
      end
    end

    def generate_docs
      formatted_prefix = @prefix.capitalize
      html = '<!doctype><html><head><title>' + formatted_prefix + ' Sprite Sheets</title><link href="' + @dst + '" rel="stylesheet">'
      html << '<style>
        ul { margin-top: 75px; }
        li {
          float: left;
          margin-right: 15px;
          list-style-type: none;
          height: 100px;
          width: 20%;
        }
        </style>'
      html << '</head><body>'

      html << '<h2>'+formatted_prefix+' Sprite Sheet</h2><p>Add the classes below to the &#60;i&#62; tag.</p>'

      html << '<ul>'
      @master_keys.each do |key|
        html << "<li><i class='#{@prefix}-#{key}'></i> #{@prefix}-#{key}</li>"
      end
      html << '</ul>'

      html << '</body></html>'

      # write html docs file
      filename = @prefix + '-sprites.html'
      file = File.open(filename, 'w') { |f| f.write(html) }

      if file > 0
        puts "Generated doc file: #{filename}"
      else
        puts "Failed to generate docs!"
      end
    end

    protected

    def get_src_contents(src)
      if @format == 'xml' or @format == 'plist'
        XmlSimple.xml_in(src)
      else
        JSON.parse(File.read(src))
      end
    end

    # checks if a given filename has an extension, if it does not then it appends default extension to filename
    def get_filename filename, extension = 'png'
      unless filename.nil?
        file_extension = get_extension filename
        filename = (file_extension.empty?) ? filename + '.' + extension : filename
      else
        false
      end
    end

    # returns the extension of a given filename
    def get_extension filename
      unless filename.nil?
        filename.to_s.scan(/\.([\w+-]+)$/).flatten
      else
        false
      end
    end

    # fatal error - prints error message to screen and exits
    def write_fatal_error message
      puts "Error: #{message}.  See spritemaster -h for usage"
      exit
    end
  end
end