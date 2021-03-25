/*
 * Author: Rahul Baruri
 * Author URI: https://gist.github.com/rbrahul
 * Source URI: https://gist.github.com/rbrahul/1345c83d993868208152c67e5985a99c
 */
var canvas = document.createElement('canvas');
canvas.width = 640;
canvas.height = 480;
var ctx = canvas.getContext('2d');
var video = document.querySelector(".html5-video-container > video");
ctx.drawImage(video, 0, 0, canvas.width, canvas.height);
var dataURI = canvas.toDataURL('image/jpeg');
console.log(dataURI);
