require "json"
require "nokogiri"

def fetch_and_replace_images(html)
  doc = Nokogiri::HTML5.fragment(html)

  doc.css("action-text-attachment").each do |attachment|
    caption = attachment["caption"]
    url = attachment["url"]

    img = Nokogiri::XML::Node.new("img", doc)
    img["src"] = url
    img["alt"] = caption || ""

    figcaption = Nokogiri::XML::Node.new("figcaption", doc)
    figcaption.content = caption

    figure = Nokogiri::XML::Node.new("figure", doc)
    figure.add_child(img)
    figure.add_child(figcaption) if caption

    attachment.replace(figure)
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
