require 'rubygems'
require 'nokogiri'
require 'rmagick'

# Convenience function used to wrap lines before writing them with RMagick
def word_wrap(text, columns = 15)
  text.split("\n").collect do |line|
    line.length > columns ? line.gsub(/(.{1,#{columns}})(\s+|$)/, "\\1\n").strip : line
  end * "\n"
end

# Step 0: data munging.
# raw HTMLs taken by simply copying the data out of the loaded webpage.
# YMMV.

blackdata = File.open("raw/blackraw.html")

doc = Nokogiri::HTML(blackdata)

blackdata.close

blackcards = {}

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

puts "OK, this will take a minute."

# Step 1: generating cards.
# True to form, they go in Helvetica.
# Cards are 2.5" wide by 3.5" tall, doing them at 300dpi for niceness of printing.
# 0.25" margin for text.

whitetitles = IO.readlines("text/white.txt")
blacktitles = IO.readlines("text/black.txt")

counter = 0

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


  img2.write "images/w#{counter}.png"
  counter += 1
end

counter = 0

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


  img2.write "images/b#{counter}.png"
  counter += 1
end



