# Hackers Against Humanity - Actually Open Remix

A Remix of Hackers Against Humanity, CC BY-NC-SA 2.0, http://hackersagainsthumanity.com.

HAH is a Remix of Cards Against Humanity, CC BY-NC-SA 2.0, http://cardsagainsthumanity.com.

Data in the "raw" directory taken from http://hackersagainsthumanity.com, and
saved here only to allow ease of processing (since the Javascript doesn't like
wget).

This code repository is intended as both a Shared-Alike copy and Shared-Alike Remix under the CC license.

All source code created by Brendan O'Connor, of Malice Afterthought, Inc.,
and released under the GPL v3 license.

All non-source code (including generated products in the Release section) released under CC BY-NC-SA 2.0.

## What it is

I was sad that I couldn't just download a PDF, ready to print, of Hackers Against Humanity. So I made one, and for ease of hacking, I'm releasing the script (so that, for instance, you could make your own cards easily).

You can also go to the Release section and simply download the images and PDFs. Images are generated at 300DPI; they are scaled down for the PDF, but I think they'll still look nice.

The Black Cards file has black squares on every other page. This is intentional, to allow you to print black on the backs of the cards using a standard duplex printer. If you don't like it, just print even pages. The White Cards file should simply be printed single-sided. The Cards Against Humanity website recommends a minimum of 80lb card stock.

Note: the Card Against Humanity website hosts a PDF of its deck that prints square cards. I don't like that much, so these PDFs are for 2"x3.5" cards.

## What it is not

These aren't guaranteed to be perfect reproductions of the HAH deck; for one thing, I don't own one, and for another, I don't have access to their source code. I also fixed a lot of typos. They do, however, look pretty similar, and if you have suggestions for improving the look, by all means let me know!

## Installation

Software Requirements:
- ruby
- ruby-dev
- imagemagick
- libmagickwand-dev

```sh
sudo apt install ruby ruby-dev imagemagick libmagickwand-dev
```

Ruby gems:
- rmagick
- nokogiri
- prawn

Install using supplied `Gemfile`:

```sh
bundle install
```

## Usage

To run:

```sh
ruby convert.rb
```

It will walk you through what it's doing. You may just pull the text files out of the HTML, generate the images, generate the PDFs, or all of the above. It will prompt before overwriting anything.

The text files, images, and PDFs in the "Release" section are all as provided by this script, except that typos have been fixed in the text files.

Note: PDF generation takes a *long* time. Like, on a decent computer it could easily take two hours. I don't know why: it's obviously a problem with the PDF generator library, and/or how I'm using it. I welcome fixes, but since it's not something you're likely to do a lot, I'm releasing as-is.

