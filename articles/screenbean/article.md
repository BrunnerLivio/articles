---
published: true
title: 'Screenbean - Pimp your screenshots'
tags: webdev, javascript, react, showdev
path: '/articles/screenbean'
date: '2022-06-22'
description: 'A tool to add colorful backgrounds to screenshots'
dev_to_path: 'https://dev.to/brunnerlivio/screenbean-pimp-your-screenshots-102m'
cover_image: 'https://res.cloudinary.com/practicaldev/image/fetch/s--dMTe7JPf--/c_imagga_scale,f_auto,fl_progressive,h_420,q_auto,w_1000/https://dev-to-uploads.s3.amazonaws.com/uploads/articles/sagfmqcsvlf9hn9z4yot.png'
---

[✨ScreenBean✨](https://screenbean.brunnerliv.io/) is a tool to add colorful backgrounds to screenshots. This idea came to me when browsing Dribbble. I've realized a lot of promo pictures have the same pattern:

- Rounded corners of the product
- Drop shadow around the product
- Background using the primary, accent or other complementary colors
- Sometimes additional complementary shapes in the background

Here is an example of the current Dribbble startpage and you can see what I mean.

![Example of Dribbble promo pictures](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/qufy21xatks150ru3rjf.PNG)



## 💡 Motivation

I often have to pitch new websites or pages to colleagues at work. Since I wanna leave a good impression, I wanna spice up my screenshots to make them stand out more. Though whenever I tried to promote my website it never looked as good as the ones on Dribbble. Probably because I am not a designer -- but I have recognized that adding things like rounded corners make a huge difference. 

After a while I wanted to automate this process. So on a boring Friday evening I wrote ScreenBean just for the fun of it.

## 📝 Technical Decisions

First and foremost I wanted to keep the app alive and "don't worry about it ever again". I don't have any interest in generating revenue with ScreenBean -- but I also don't wanna loose money. So I tried to implement everything client-side. For sure it would be the better technical decision to use a Serverless function to, for instance, generate the images. Though in my context I just didn't want to spend a dime.

## 👨‍💻 Tech Stack

At the heart of ScreenBeans implementation are two libraries from NPM:

- [html-to-image](https://www.npmjs.com/package/html-to-image): Generate images from DOM elements client-side 
- [node-vibrant](https://www.npmjs.com/package/node-vibrant): Extract prominent colors from an image

So with these two libraries all I had to do was essentially creating the images using normal HTML/CSS dynamically. Then I can just generate the *.png graphic using html-to-image. Thanks to node-vibrant I can take prominent colors of the image so it usually looks complementary.

I have used React to help me with building the different preview images, the upload mechanism and saving the images. 

Since the application is client-side only I could just use free-tier of Netlify for my deployment.

I am a huge fan of TypeScript, though for this project I have decided not to use it. Since I don't need to handle a lot of data throughout the application there did not seem to be a huge benefit of using it. 

---

[Demo](https://screenbean.brunnerliv.io/) | [Github](https://github.com/BrunnerLivio/screenbean.brunnerliv.io)





