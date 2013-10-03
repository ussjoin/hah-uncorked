require 'rubygems'
require 'nokogiri'
require 'rmagick'
require 'prawn' # Not the base! It doesn't have image tables! Use:
# gem install specific_install
# gem specific_install https://github.com/prawnpdf/prawn.git

# Convenience function used to wrap lines before writing them with RMagick
def word_wrap(text, columns = 15)
  text.split("\n").collect do |line|
    line.length > columns ? line.gsub(/(.{1,#{columns}})(\s+|$)/, "\\1\n").strip : line
  end * "\n"
end

# Step 0: data munging.
# raw HTMLs taken by simply copying the data out of the loaded webpage.
# YMMV.

def rawtotext
  blackdata = File.open("raw/blackraw.html")

  doc = Nokogiri::HTML(blackdata)

  blackdata.close

  blackcards = {}

  # Why do it like this instead of //strong ?
  # Because I thought I might want the "explanations" available for some cards.
  # But I'm not using them right now. So, nbd.

  doc.xpath('//p').each do |item|
    title = ""
    exp = ""
    item.children.each do |child|
      if child.element?
        title = item.content
      else
        exp = item.content
      end
    end
    blackcards[title] = exp
  end

  whitedata = File.open("raw/whiteraw.html")

  doc = Nokogiri::HTML(whitedata)

  whitedata.close

  whitecards = {}

  doc.xpath('//p').each do |item|
    title = ""
    exp = ""
    item.children.each do |child|
      if child.element?
        title = item.content
      else
        exp = item.content
      end
    end
    whitecards[title] = exp
  end

  # Step 0.5: Generating plain text lists.
  # Since there are weird encoding problems in the input, this is a simple way to demunge.

  File.open("text/white.txt", "w") { |f|
    whitecards.keys.each do |wht|
      f.puts wht
    end
  }

  File.open("text/black.txt", "w"){ |f|
    blackcards.keys.each do |blk|
      f.puts blk
    end
  }

  # Step 0.75: Prompt user to fix the files.
  puts "I have just written two files: text/white.txt, and text/black.txt."
  puts "You should now go through them and fix any typos, or delete any blank lines."
  puts "Press ENTER to continue."

  gets

  puts "OK, files accepted."
  
end

def texttocards
  
  puts "Entering conversion from plain text to card PNGs."
  
  # Step 1: generating cards.
  # True to form, they go in Helvetica.
  # Cards are 2.5" wide by 3.5" tall, doing them at 300dpi for niceness of printing.
  # 0.25" margin for text.

  whitetitles = IO.readlines("text/white.txt")
  blacktitles = IO.readlines("text/black.txt")

  whitecounter = -1

  whitetitles.each do |wht|
    img = Magick::Image.new(750,1050){
      self.background_color = 'white'
    }

    gc = Magick::Draw.new

    offset = 0

    word_wrap(wht).each_line do |row|
      gc.annotate(img, 600, 900, 75, (offset += 85), row) {
        self.font_family = 'Arial'
        #self.fill = 'black'
        self.stroke = 'black'
        self.pointsize = 64
        self.font_weight = Magick::BoldWeight
        self.gravity = Magick::NorthWestGravity
      }
    end

    gc.annotate(img, 600, 1000, 150, 0, "Hackers Against Humanity") {
      self.font_family = 'Arial'
      #self.fill = 'black'
      self.stroke = 'black'
      self.pointsize = 24
      self.font_weight = Magick::BoldWeight
      self.gravity = Magick::SouthWestGravity
    }

    logo = Magick::Image::read("cahhacker.png")[0]

    img2 = img.composite(logo, 75, 950, Magick::OverCompositeOp)

    whitecounter += 1
    img2.write "images/w#{whitecounter}.png"
  end

  blackcounter = -1

  blacktitles.each do |blk|
    img = Magick::Image.new(750,1050){
      self.background_color = 'black'
    }

    gc = Magick::Draw.new

    offset = 0

    word_wrap(blk).each_line do |row|
      gc.annotate(img, 600, 900, 75, (offset += 85), row) {
        self.font_family = 'Arial'
        self.fill = 'white'
        self.stroke = 'white'
        self.pointsize = 64
        self.font_weight = Magick::BoldWeight
        self.gravity = Magick::NorthWestGravity
      }
    end

    gc.annotate(img, 600, 1000, 150, 0, "Hackers Against Humanity") {
      self.font_family = 'Arial'
      self.fill = 'white'
      self.stroke = 'white'
      self.pointsize = 24
      self.font_weight = Magick::BoldWeight
      self.gravity = Magick::SouthWestGravity
    }

    logo = Magick::Image::read("cahhacker.png")[0]

    img2 = img.composite(logo, 75, 950, Magick::OverCompositeOp)


    blackcounter += 1
    img2.write "images/b#{blackcounter}.png"
  end
  
  puts "Card PNG writing complete."
end

def cardstopdf
  # Step 2: Generating PDF.
  # Each card is 2.5" wide, 3.5" tall.
  # Portrait: 3 wide with 0.5" margins on each side, 3 tall with 0.5" margins on each side.

  # Black cards will be printed on even pages only, with solid black to the boundaries on odd.
  # This will make sure their backs are black.
  # Cut lines will be printed in white.

  # White cards will be printed on all pages; make sure to have them printed single-sided.
  # Cut lines will be printed in black.


  # Note: Prawn defaults to portrait, 0.5" margin all the way around, letter size.
  # As that's perfect, we won't change it.

  # White: 0-277
  # Black: 0-80

  blackcounter = 80
  whitecounter = 277

  Prawn::Document.generate('pdf/blackcards.pdf'){
    width = bounds.right - bounds.left
    height = bounds.top - bounds.bottom
    cardw = width / 3.0
    cardh = height / 3.0
  
    (0..blackcounter).step(9) do |n|
      # Draw an enormous black rectangle.
      # Origin is at lower left.
  
      puts "Now drawing fill rectangle"
      # Fill_rectangle draws toward the bottom right.
      fill_rectangle bounds.top_left, width, height
  
      # Go to next page.
      start_new_page
    
      puts "Now drawing Black Card images #{n}-#{n+8}"
    
      if FileTest.exists?("images/b#{n}.png")
        image "images/b#{n}.png", :at => [bounds.left, bounds.top], :width => cardw, :height => cardh
      end
      if FileTest.exists?("images/b#{n+1}.png")
        image "images/b#{n+1}.png", :at => [bounds.left + cardw, bounds.top], :width => cardw, :height => cardh
      end
      if FileTest.exists?("images/b#{n+2}.png")
        image "images/b#{n+2}.png", :at => [bounds.left + 2.0*cardw, bounds.top], :width => cardw, :height => cardh
      end

      if FileTest.exists?("images/b#{n+3}.png")
        image "images/b#{n+3}.png", :at => [bounds.left, bounds.top - cardh], :width => cardw, :height => cardh
      end
      if FileTest.exists?("images/b#{n+4}.png")
        image "images/b#{n+4}.png", :at => [bounds.left + cardw, bounds.top - cardh], :width => cardw, :height => cardh
      end
      if FileTest.exists?("images/b#{n+5}.png")
        image "images/b#{n+5}.png", :at => [bounds.left + 2.0*cardw, bounds.top - cardh], :width => cardw, :height => cardh
      end

      if FileTest.exists?("images/b#{n+6}.png")
        image "images/b#{n+6}.png", :at => [bounds.left, bounds.top - 2*cardh], :width => cardw, :height => cardh
      end
      if FileTest.exists?("images/b#{n+7}.png")
        image "images/b#{n+7}.png", :at => [bounds.left + cardw, bounds.top - 2*cardh], :width => cardw, :height => cardh
      end
      if FileTest.exists?("images/b#{n+8}.png")
        image "images/b#{n+8}.png", :at => [bounds.left + 2.0*cardw, bounds.top - 2*cardh], :width => cardw, :height => cardh
      end
  
      puts "Now drawing cut lines"
  
      stroke_color "FFFFFF"
      stroke_line bounds.top_left, bounds.top_right
      stroke_line bounds.top_left, bounds.bottom_left
      stroke_line bounds.top_right, bounds.bottom_right
      stroke_line bounds.bottom_left, bounds.bottom_right
      stroke_line [bounds.left, bounds.top-cardh], [bounds.right, bounds.top-cardh]
      stroke_line [bounds.left, bounds.top-2*cardh], [bounds.right, bounds.top-2*cardh]
      stroke_line [bounds.left+cardw, bounds.top], [bounds.left+cardw, bounds.bottom]
      stroke_line [bounds.left+2*cardw, bounds.top], [bounds.left+2*cardw, bounds.bottom]
    
      puts "Black Cards #{n}-#{n+8} of #{blackcounter} written"
    
      if n+9 < blackcounter
        start_new_page
      end
    
    end
  }
  
  Prawn::Document.generate('pdf/whitecards.pdf'){
    width = bounds.right - bounds.left
    height = bounds.top - bounds.bottom
    cardw = width / 3.0
    cardh = height / 3.0
  
    (0..whitecounter).step(9) do |n|
      puts "Now drawing PDF White Card images #{n}-#{n+8}"
    
      if FileTest.exists?("images/w#{n}.png")
        image "images/w#{n}.png", :at => [bounds.left, bounds.top], :width => cardw, :height => cardh
      end
      if FileTest.exists?("images/w#{n+1}.png")
        image "images/w#{n+1}.png", :at => [bounds.left + cardw, bounds.top], :width => cardw, :height => cardh
      end
      if FileTest.exists?("images/w#{n+2}.png")
        image "images/w#{n+2}.png", :at => [bounds.left + 2.0*cardw, bounds.top], :width => cardw, :height => cardh
      end

      if FileTest.exists?("images/w#{n+3}.png")
        image "images/w#{n+3}.png", :at => [bounds.left, bounds.top - cardh], :width => cardw, :height => cardh
      end
      if FileTest.exists?("images/w#{n+4}.png")
        image "images/w#{n+4}.png", :at => [bounds.left + cardw, bounds.top - cardh], :width => cardw, :height => cardh
      end
      if FileTest.exists?("images/w#{n+5}.png")
        image "images/w#{n+5}.png", :at => [bounds.left + 2.0*cardw, bounds.top - cardh], :width => cardw, :height => cardh
      end

      if FileTest.exists?("images/w#{n+6}.png")
        image "images/w#{n+6}.png", :at => [bounds.left, bounds.top - 2*cardh], :width => cardw, :height => cardh
      end
      if FileTest.exists?("images/w#{n+7}.png")
        image "images/w#{n+7}.png", :at => [bounds.left + cardw, bounds.top - 2*cardh], :width => cardw, :height => cardh
      end
      if FileTest.exists?("images/w#{n+8}.png")
        image "images/w#{n+8}.png", :at => [bounds.left + 2.0*cardw, bounds.top - 2*cardh], :width => cardw, :height => cardh
      end
  
      puts "Now drawing cut lines"
  
      stroke_color "000000"
      stroke_line bounds.top_left, bounds.top_right
      stroke_line bounds.top_left, bounds.bottom_left
      stroke_line bounds.top_right, bounds.bottom_right
      stroke_line bounds.bottom_left, bounds.bottom_right
      stroke_line [bounds.left, bounds.top-cardh], [bounds.right, bounds.top-cardh]
      stroke_line [bounds.left, bounds.top-2*cardh], [bounds.right, bounds.top-2*cardh]
      stroke_line [bounds.left+cardw, bounds.top], [bounds.left+cardw, bounds.bottom]
      stroke_line [bounds.left+2*cardw, bounds.top], [bounds.left+2*cardw, bounds.bottom]
    
      puts "White Cards #{n}-#{n+8} of #{whitecounter} written"
    
      if n+9 < whitecounter
        start_new_page
      end
    
    end
  }
end


if FileTest.exists?('text/black.txt') and FileTest.exists?('text/white.txt')
  puts "It appears that you already have the text lists of cards."
  puts "Overwriting them will destroy all changes you may have made."
  print "Would you like to overwrite them? [y/N]: "
  answer = gets
  if answer.downcase[0] == "y"
    rawtotext
  end
else
  rawtotext
end

if FileTest.exists?('images/b1.png') and FileTest.exists?('images/w1.png')
  puts "It appears that you already have generated card images."
  puts "Overwriting them will destroy all changes you may have made."
  print "Would you like to overwrite them? [y/N]: "
  answer = gets
  if answer.downcase[0] == "y"
    texttocards
  end
else
  texttocards
end

puts "Generating PDFs is optional and time-consuming."
print "Would you like to generate PDFs, suitable for printing? [y/N]: "
answer = gets
if answer.downcase[0] == "y"
  if FileTest.exists?('pdf/blackcards.pdf') and FileTest.exists?('pdf/whitecards.pdf')
    puts "It appears that you already have generated PDFs."
    puts "Overwriting them will destroy all changes you may have made."
    print "Would you like to overwrite them? [y/N]: "
    answer2 = gets
    if answer2.downcase[0] == "y"
      cardstopdf
    end
  else
    cardstopdf
  end
end