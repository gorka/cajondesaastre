require "json"
require "nokogiri"
require "open-uri"

def download_image(url)
  filename = File.basename(URI.parse(url).path)
  save_path = File.join("assets", "img", filename)

  begin
    URI.open(url, "r", redirect: true) do |remote_file|

      File.open(save_path, "wb") do |file|
        file.write(remote_file.read)
      end
    end

    return save_path
  rescue => e
    puts "Error downloading image from #{url}: #{e.message}"
  end
end

def fetch_and_replace_images(html)
  doc = Nokogiri::HTML5.fragment(html)

  doc.css("action-text-attachment").each do |attachment|
    caption = attachment["caption"]
    url = attachment["url"]

    file_path = download_image(url)

    img = Nokogiri::XML::Node.new("img", doc)
    img["src"] = "/#{file_path}"
    img["alt"] = caption || ""

    attachment.replace(img)
  end

  doc.to_html
end

podcasts = JSON.parse File.read('_data/podcasts.json')

posts = podcasts.map do |podcast|
  podcast = <<-PODCAST
---
layout: post

title: "##{podcast["number"]} - #{podcast["title"]}"
published: #{podcast["published_at"]}
excerpt_separator: <!--more-->

episode_number: #{podcast["number"]}
image_url: #{podcast["image_url"]}
mp3_url: #{podcast["mp3_url"]}
duration: #{podcast["duration"]}
length: #{podcast["length"]}
---
#{podcast["description"]}<!--more-->

<audio controls src="#{podcast["mp3_url"]}"></audio>

#{fetch_and_replace_images(podcast["html"]["body"])}
  PODCAST

  podcast
end

posts.each_with_index do |post, index|
  File.write("_posts/#{podcasts[index]["published_at"]}-#{podcasts[index]["slug"]}.md", post)
end
