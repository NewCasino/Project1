/*******************************************************************************
 * jquery.freshline.saloon.js - jQuery Plugin for Simple Slides Plugin
 * @version: 1.0 (10.01.2012)
 * @requires jQuery v1.2.2 or later 
 * @author Krisztian Horvath
********************************************************************************/




(function($,undefined){	
	
	
	
	////////////////////////////
	// THE PLUGIN STARTS HERE //
	////////////////////////////
	
	$.fn.extend({
	
		
		// OUR PLUGIN HERE :)
		saloon: function(options) {
	
		
			
		////////////////////////////////
		// SET DEFAULT VALUES OF ITEM //
		////////////////////////////////
		var defaults = {	
			width:200,
			height:100,
			speed:1000,
			delay:500,
			direction:"vertical",
			thumbs:"bottom",			
			googleFonts:'PT+Sans+Narrow:400,700',
			googleFontJS:'http://ajax.googleapis.com/ajax/libs/webfont/1/webfont.js'
		};
		
			options = $.extend({}, $.fn.saloon.defaults, options);
		
			WebFontConfig = {
						google: { families: [ options.googleFonts ] },
						active: function() { jQuery('body').data('googlefonts','loaded');},
						inactive: function() { jQuery('body').data('googlefonts','loaded');}
					};
					
			return this.each(function() {
			
				var opt=options;
				
				opt.speedGood = opt.speed;
				opt.speed=0;
				// GOOGLE FONT HANDLING
				if (opt.googleFonts!=undefined && opt.googleFonts.length>0) {
					var wf = document.createElement('script');
					wf.src = opt.googleFontJS;
					wf.type = 'text/javascript';
					wf.async = 'true';
					var s = document.getElementsByTagName('script')[0];
					s.parentNode.insertBefore(wf, s);
					jQuery('body').data('googlefonts','wait');
				} else {
					jQuery('body').data('googlefonts','loaded');
				}
				
				
				//console.log('Banner jQuery Plugin Activated');
				
				
				if (opt.direction=="vertical") 
					opt.direction="down" 
				else
					if (opt.direction=="horizontal") 
						opt.direction="right" 
					
					
				opt.actbanner = -1;
				opt.nextbanner = 0;
								
				$(this).wrapInner('<div style="position:relative;width:'+opt.width+'px;height:'+opt.height+'px;overflow:hidden"></div>');
				
				var main=$(this).find('div:first');
				main.append('<div class="banner-preloader"></div>');
				
				main.waitForImages(function() {   
					var waitForWF = setInterval(function() {
										
										if ($('body').data('googlefonts') != undefined && $('body').data('googlefonts')=="loaded") {
											
											clearInterval(waitForWF);
											
											prepareSlides(main,opt);
											createBullets(main,opt)
											rotateSlides(main,opt);
											countDown(main,opt);
											
											
											if (anyTouch())
											{
												setTouchWipe(main,opt);
											} else {
												if (opt.grab=="on") {
													checkMouseMovements(main,opt);
													main.addClass('grab-cursor');
												}											
											}
											
											main.find('.banner-preloader').animate({'opacity':0},{durataion:400,queue:false});
											setTimeout(function() {main.find('.banner-preloader').remove()},400);

										}
									},100);				
				});
				
				opt.mouseover=false;
				opt.down=false;
				opt.overthumbs=false;
				
				
				
				main.hover(
					function() {
						opt.mouseover=true;
						
					}, 
					function() {
						opt.mouseover=false;
						main.mouseup();
				});
				
			})
	}
})
	

					/////////////////////
					// TOUCH DEVICE ?? //
					////////////////////
					function anyTouch() {
						//console.log('Check Mobile Devie');
						if( navigator.userAgent.match(/Android/i) ||
												 navigator.userAgent.match(/webOS/i) ||
												 navigator.userAgent.match(/iPhone/i) ||
												 navigator.userAgent.match(/iPod/i) ||
												 navigator.userAgent.match(/iPad/i) ||
												 navigator.userAgent.match(/ipad/i) ||
												 navigator.userAgent.match(/BlackBerry/)
												 )
												return true;
											else
												return false;
					}


					//////////////////////////////////////////////
					//	TOUCH WIPE FUNCTION FOR IPHONE AND IPAD	//
					/////////////////////////////////////////////
					function setTouchWipe(main,opt) {
						if (opt.direction=="right")
								main.swipe( {data:main, 
																swipeLeft:function() 
																		{ 																		
																			var nextbanner = opt.actbanner-1;
																			if (nextbanner <0) nextbanner=opt.maxbanner-1;																			
																			main.find('#minithumb'+nextbanner).click();
																																						
																		}, 
																swipeRight:function() 
																		{																				
																				var nextbanner=opt.actbanner+1;
																				if (nextbanner>opt.maxbanner-1) opt.nextbanner=0;
																				main.find('#minithumb'+nextbanner).click();
																		}, 
															allowPageScroll:"auto"} );
															
					if (opt.direction=="down")
								main.swipe( {data:main, 
																swipeUp:function() 
																		{ 																		
																			var nextbanner = opt.actbanner-1;
																			if (nextbanner <0) nextbanner=opt.maxbanner-1;																			
																			main.find('#minithumb'+nextbanner).click();
																																						
																		}, 
																swipeDown:function() 
																		{																				
																				var nextbanner=opt.actbanner+1;
																				if (nextbanner>opt.maxbanner-1) opt.nextbanner=0;
																				main.find('#minithumb'+nextbanner).click();
																		}, 
															allowPageScroll:"auto"} );

					}
	
					///////////////////////
					// CHECK MOUSE DRAGS //
					///////////////////////
					function checkMouseMovements(main,opt) {
					
						
						
						var glas=main.find('.glas');
						
						main.mousedown(function() {
							if (main.hasClass('grab-cursor'))
								if (opt.direction=="up" || opt.direction=="down") {
									$(this).addClass('grabbing-vertical-cursor');								
								} else {
									$(this).addClass('grabbing-horizontal-cursor');
								}
								
							opt.prepared=false;
							
							if (opt.animateon==false && opt.overthumbs==false) {
							
											main.find('.topcreative').remove();
											
										opt.down=true;
										opt.justpressed=true;	
										
										opt.mouseYoffset=opt.pagey;
										opt.mouseXoffset=opt.pagex;
										
										
										var resetCome=false;
										
										///////////////////////////////////////////////////
										//	IN CASE THE ITEM SHOULD BE FLIPPED UP / DOWN //
										///////////////////////////////////////////////////
										if (opt.direction=="up" || opt.direction=="down") {
											if (opt.pagey>=0 && opt.pagey<opt.height/2) {
												
												opt.nextbanner=opt.actbanner+1;
												if (opt.nextbanner>opt.maxbanner-1) opt.nextbanner=0;
												opt.rolldirection="down";																
											} else {
												opt.nextbanner = opt.actbanner-1;
												if (opt.nextbanner <0) opt.nextbanner=opt.maxbanner-1;
												opt.rolldirection="up" ;
											}
											
											

											// GET THE DIVS WE NEED
											var canvas_go=main.find('.canvas-go');												
											var canvas_go_blur=main.find('.canvas-go-blur');																		
											var canvas_come=main.find('.canvas-come');
											var bbox_come=main.find('.blackbox-come');																	
											
											
											// SOURCE PREPEARING											
											
											canvas_go.attr('src',main.find('li:eq('+opt.actbanner+') img:first').attr('src'));											
											canvas_go_blur.attr('src',main.find('li:eq('+opt.actbanner+') img:first').attr('src'));																																												
											setTimeout(function() {
												canvas_come.css({'height':'0px'});											
												canvas_go.css({'height':opt.height+'px','top':'0px'});
												
											},50);
											setTimeout(function() {
												canvas_come.attr('src',main.find('li:eq('+opt.nextbanner+') img:first').attr('src'));											
												opt.prepared=true;
											},100);
										}
										
										//////////////////////////////////////////////////////
										//	IN CASE THE ITEM SHOULD BE FLIPPED LEFT / RIGHT //
										//////////////////////////////////////////////////////
										if (opt.direction=="left" || opt.direction=="right") {
											if (opt.pagex>=0 && opt.pagex<opt.width/2) {
												opt.nextbanner = opt.actbanner-1;
												if (opt.nextbanner <0) opt.nextbanner=opt.maxbanner-1;
												opt.rolldirection="right" ;
											} else {
												opt.nextbanner=opt.actbanner+1;
												if (opt.nextbanner>opt.maxbanner-1) opt.nextbanner=0;
												opt.rolldirection="left";																
											}
											
											

											// GET THE DIVS WE NEED
											var canvas_go=main.find('.canvas-go');												
											var canvas_go_blur=main.find('.canvas-go-blur');																		
											var canvas_come=main.find('.canvas-come');
											var bbox_come=main.find('.blackbox-come');																	
											
											
											// SOURCE PREPEARING											
											
											canvas_go.attr('src',main.find('li:eq('+opt.actbanner+') img:first').attr('src'));											
											canvas_go_blur.attr('src',main.find('li:eq('+opt.actbanner+') img:first').attr('src'));																																												
											setTimeout(function() {
												canvas_come.css({'width':'0px'});											
												canvas_go.css({'width':opt.width+'px','left':'0px'});
												
											},50);
											setTimeout(function() {
												
												canvas_come.attr('src',main.find('li:eq('+opt.nextbanner+') img:first').attr('src'));											
												opt.prepared=true;
											},100);
										}
							}
						});

						
						////////////////////////////////
						// IF MOUSE HAS BEEN RELEASED//
						//////////////////////////////
						main.mouseup(function() {
						opt.speed = opt.speedGood;
						 $(this).removeClass('grabbing-horizontal-cursor');
						 $(this).removeClass('grabbing-vertical-cursor');
						 if (opt.down==true && opt.animateon==false) {
									opt.down=false;		
									var dir=opt.direction;							

									if (opt.rolldirection=="up" || opt.rolldirection=="down") {
										if (opt.pagey/opt.height >0.5) dir="down";																			
										if (opt.pagey/opt.height <0.5) dir="up";								
									}
									
									if (opt.rolldirection=="left" || opt.rolldirection=="right") {
										if (opt.pagex/opt.width >0.5) dir="right";																			
										if (opt.pagex/opt.width <0.5) dir="left";								
									}
									
									if (opt.rolldirection != dir) 
										rotateBack(main,opt,opt.rolldirection)
									else
										finnishRotate(main,opt,opt.rolldirection);
							}
						});

						
						$(document).mousemove(function(e){
								$('body').data('banpagex',e.pageX);
								$('body').data('banpagey',e.pageY);
								
						}); 
						
						
						// REPEATLY CALL THE FUNCTION, TO KNOW IF WE CAN "ROTATE" PER MOUSE THE ITEM
						main.hover(
							function() {
							var main=$(this);
							
							main.data("interval",setInterval(function() {						
									opt.pagex = $('body').data('banpagex') - parseInt(main.offset().left,0);
									opt.pagey = $('body').data('banpagey') - parseInt(main.offset().top,0);
									
									if (opt.pagex<0) opt.pagex=0;
									if (opt.pagex>opt.width) opt.pagex=opt.width;
									
									if (opt.pagey<0) opt.pagey=0;
									if (opt.pagey>opt.height) opt.pagex=opt.height;
									
									if (opt.down==true && opt.animateon==false && opt.mouseover==true && opt.prepared) {																														
										
										moveCubeToPosition(main,opt);
									}
								},2));
							},
							function() {								
								var main=$(this);
								clearInterval(main.data('interval'));					
							});
					}
		
		
		
		
		
		
		
		
		
		
					///////////////////////////////
					//  --  LOCALE FUNCTIONS -- //
					///////////////////////////////
					
					function prepareSlides(main,opt) {
						main.find("ul").css({'list-style':'none',
										'margin': 0,
										'padding': 0});
						main.wrap('<div class="banner_rotator_holder" style="width:'+(opt.width)+'px;height:'+(opt.height)+'px;overflow:hidden"></div>');
						
						opt.maxbanner=0;
						
						main.find('li').each(function(i) {
							var $this=$(this);				
							$this.wrapInner('<div class="bslide" style="position:absolute;width:'+opt.width+'px;height:'+opt.height+'px;overflow:hidden"></div>');
							
							// DEFINE BANNER
							var banner=$this.find('.bslide');
							
							// HIDE THE IMG 
							var img = banner.find('img')
							img.css({'display':'none'});								
							opt.maxbanner++;
							
							//$this.find('.creative_layer').css({'visibility':'hidden'});
						});
						main.append('<div class="glas" style="position:absolute;top:0px;left:0px;z-index:40;width:'+(opt.width)+'px;height:'+(opt.height)+'px;overflow:hidden"></div>');
					}
								
			


			
			
			
			
			
					///////////////////////////
					// CREATE THE BULLETS   //
					//////////////////////////
					function createBullets(top,opt) {
						
						var maxitem = top.find('ul >li').length;
						
											
						// CALCULATE THE MAX WIDTH OF THE THUMB HOLDER
						var full = opt.width;
						
						// Create BULLET CONTAINER
						top.append('<div class="thumbbuttons"><div class="grainme"><div class="leftarrow"></div><div class="thumbs"></div><div class="rightarrow"></div></div></div>');
						var leftb = top.find('.leftarrow');
						var rightb = top.find('.rightarrow');
																
						var minithumbs = top.find('.thumbs');
						
							
						
						
						// GO THROUGHT THE ITEMS, AND CREATE AN THUMBNAIL AS WE NEED
						top.find('ul >li').each(function(i) {
									
									var $this=$(this);
									
									var thumb_mini=$('<div class="minithumb" id="minithumb'+i+'"></div>');
									if (i==0) thumb_mini.addClass('selected');

									thumb_mini.data('id',i);
									minithumbs.append(thumb_mini);
																											
									thumb_mini.click(function() {									
										var $this=$(this);		
										opt.count=9999999;
										opt.nextbanner = $this.index();																		
										opt.thumbclicked=true;
									});
									
									thumb_mini.hover(
										function() { opt.overthumbs=true; },
										function() { opt.overthumbs=false;});
										
								
							});
							
							minithumbs.waitForImages(function() {
								var y=0;
								if (opt.thumbs=="bottom") 
									y= (opt.height-parseInt(minithumbs.height(),0)) - opt.thumbsYOffset;								 								
								else
									if (opt.thumbs=="none") 
										minithumbs.css({'visibility':'hidden'})
									else
										if (opt.thumbs=="center") 
											y= (opt.height/2 -parseInt(minithumbs.height()/2,0)) - opt.thumbsYOffset;								 								
									
								minithumbs.parent().parent().css({'opacity':'0.0','left':(opt.thumbsXOffset)+(full/2 - parseInt(minithumbs.parent().width(),0)/2)+"px", 'top':y+"px"});
								
								
							});
							
							top.hover(
								function(){
									
									var $this=$(this);
									var thumbs=$this.find('.thumbbuttons')									
									thumbs.stop();
									thumbs.animate({'opacity':'1.0'},{duration:400,queue:false});
									
								},
								function() {
									var $this=$(this);
									var thumbs=$this.find('.thumbbuttons')
									thumbs.stop();
									thumbs.animate({'opacity':'0.0'},{duration:200,queue:false});
									
								});
							
					}
					
			///////////////////////////////////////////////////
			// ROTATE THE CUBE DEPEND ON THE MOUSE POSITION //
			//////////////////////////////////////////////////
			function moveCubeToPosition(main,opt) {
							opt.speed = opt.speedGood;
				////console.log("Banner Currently Dragged And Moved");
				// GET THE DIVS WE NEED
				var canvas_go=main.find('.canvas-go');												
				var canvas_go_blur=main.find('.canvas-go-blur');																		
				var canvas_come=main.find('.canvas-come');
				var bbox_go=main.find('.blackbox-go');
				var bbox_come=main.find('.blackbox-come');
										
				
				// CALCULATE THE RANGES
				var ranges=getRange(opt,true,opt.rolldirection);
				var go = ranges.go;
				var co = ranges.co;								
								
				
				//RMOVE THE CREATIVE LAYERS FROM THE TOP
				main.find('.topcreative').remove();								
				
				//console.log('width:'+go.w+'px height:'+go.h+'px  top:'+go.y+'px left:'+go.x+'px');
				
				canvas_go.css({'opacity':1,		'width':go.w+"px", 'height':go.h+"px", 'position':'absolute', 'top':go.y+'px', 'left':go.x+'px'});
				canvas_go_blur.css({'opacity':0,'width':go.w+"px", 'height':go.h+"px", 'position':'absolute', 'top':go.y+'px', 'left':go.x+'px'});
				canvas_come.css({'opacity':1,	'width':co.w+"px", 'height':co.h+"px", 'position':'absolute', 'top':co.y+'px', 'left':co.x+'px'});
											
				bbox_go.css({'opacity':opt.opaprocgo, 'top':go.y+"px", 'left':go.x+"px", 'height':go.h+'px',  'width':go.w+"px"});
				bbox_come.css({'opacity':opt.opaprocco, 'top':co.y+"px", 'left':co.x+'px', 'height':co.h+'px', 'width':co.w+"px"});
			
				// SOURCE PREPEARING
				canvas_go.attr('src',main.find('li:eq('+opt.actbanner+') img:first').attr('src'));
				canvas_go_blur.attr('src',main.find('li:eq('+opt.actbanner+') img:first').attr('src'));
				canvas_come.attr('src',main.find('li:eq('+opt.nextbanner+') img:first').attr('src'));
							
			}
			
			
			
			
			
			///////////////////////////////////////////////////////////////////
			// ROTATE THE SLIDES FINNISHING THE ROTATED CUBE VIA DRAG & DROP //
			///////////////////////////////////////////////////////////////////
			function finnishRotate(main,opt,direction) {
				opt.speed = opt.speedGood;
				//console.log("Finish Rotation");
				// GET THE DIVS WE NEED
				var canvas_go=main.find('.canvas-go');												
				var canvas_go_blur=main.find('.canvas-go-blur');																		
				var canvas_come=main.find('.canvas-come');
				var bbox_go=main.find('.blackbox-go');
				var bbox_come=main.find('.blackbox-come');
										
				// SOURCE PREPEARING
				canvas_go.attr('src',main.find('li:eq('+opt.actbanner+') img:first').attr('src'));
				canvas_go_blur.attr('src',main.find('li:eq('+opt.actbanner+') img:first').attr('src'));

				// CALCULATE THE RANGES
				var ranges=getRange(opt,false,direction);
				var go = ranges.go;
				var co = ranges.co;								
																				
				// OK ANIMATION IS ON
				opt.animateon = true;
				
				//RMOVE THE CREATIVE LAYERS FROM THE TOP
				main.find('.topcreative').animate({'opacity':'0.0'},{duration:100,queue:false});
				
				
				// WE NEED A LITTLE DELAY TO PREPARE THE ITEMS SO FAR
				setTimeout(function() {
				
					main.find('.topcreative').remove();
					// PREPARE THE ACTUAL DIVS HERE
					
																														
					canvas_go.animate({	'opacity':1,		'top':go.y2+"px", 'left':go.x2+"px", 'height':go.h2+'px',  'width':go.w2+"px"},{duration:opt.speedrest,queue:false, complete:function() { opt.animateon=false; }});
					canvas_go_blur.animate({	'top':(go.y2+2)+"px", 'left':(go.x2+2)+'px', 'height':go.h2+'px', 'width':go.w2+"px", 'opacity':'0.8'},{duration:opt.speedrest,queue:false});
					
					canvas_come.animate({		'top':co.y2+"px", 'left':co.x2+'px', 'height':co.h2+'px', 'width':co.w2+"px"},{duration:(opt.speedrest-20),queue:false});
					
					bbox_go.animate({'opacity':0.9, 'top':go.y2+"px", 'left':go.x2+"px", 'height':go.h2+'px',  'width':go.w2+"px"},{duration:opt.speedrest,queue:false});
					
					bbox_come.animate({'opacity':0.0, 'top':co.y2+"px", 'left':co.x2+'px', 'height':co.h2+'px', 'width':co.w2+"px"},{duration:opt.speedrest,queue:false});		
					
					canvas_come.attr('src',main.find('li:eq('+opt.nextbanner+') img:first').attr('src'));
					
					
					main.find('li:eq('+opt.nextbanner+') .creative_layer').clone().appendTo(main).addClass("topcreative");
					main.find('.topcreative').css({'position':'absolute','top':'0px','left':'0px','z-index':49,'width':opt.width+"px",'height':opt.height+"px"});
					textanim(main,opt.speedrest);
					
					// SET THE DELAY A BIT LONGER THAN STANDARD
					if (main.find('li:eq('+opt.nextbanner+')').data('delayoffset') != undefined)
						opt.doffset=main.find('li:eq('+opt.nextbanner+')').data('delayoffset');
					else
						opt.doffset=0;
						
					// SET NEXT BANNER TO THE ACTIVE BANNER
					opt.prevbanner=opt.actbanner;
					opt.actbanner=opt.nextbanner;
					opt.nextbanner = opt.nextbanner+1;
					if (opt.nextbanner>main.find('li').length-1) opt.nextbanner=0;	
					main.find('.minithumb').removeClass('selected');				
					main.find('#minithumb'+(opt.actbanner)).addClass('selected');	
					
					
				},100);				
			}
			
			
			///////////////////////////////////////////////////////////////////
			// ROTATE THE SLIDES FINNISHING THE ROTATED CUBE VIA DRAG & DROP //
			///////////////////////////////////////////////////////////////////
			function rotateBack(main,opt,direction) {
				
				opt.speed = opt.speedGood;
				// GET THE DIVS WE NEED
				var canvas_go=main.find('.canvas-go');												
				var canvas_go_blur=main.find('.canvas-go-blur');																		
				var canvas_come=main.find('.canvas-come');
				var bbox_go=main.find('.blackbox-go');
				var bbox_come=main.find('.blackbox-come');
										
				// SOURCE PREPEARING
				canvas_go.attr('src',main.find('li:eq('+opt.actbanner+') img:first').attr('src'));
				canvas_go_blur.attr('src',main.find('li:eq('+opt.actbanner+') img:first').attr('src'));

				// CALCULATE THE RANGES
				var ranges=getRange(opt,false,direction);
				var go = ranges.go;
				var co = ranges.co;								
																				
				// OK ANIMATION IS ON
				opt.animateon = true;
				
				//RMOVE THE CREATIVE LAYERS FROM THE TOP
				main.find('.topcreative').animate({'opacity':'0.0'},{duration:100,queue:false});
				
				opt.speedrest = opt.speed-opt.speedrest;
				// WE NEED A LITTLE DELAY TO PREPARE THE ITEMS SO FAR
				setTimeout(function() {
				
					main.find('.topcreative').remove();
					// PREPARE THE ACTUAL DIVS HERE
					
																														
					canvas_go.animate({	'opacity':1,		'top':go.y+"px", 'left':go.x+"px", 'height':go.h+'px',  'width':go.w+"px"},{duration:opt.speedrest,queue:false, complete:function() { opt.animateon=false; }});
					canvas_go_blur.animate({	'top':(go.y+2)+"px", 'left':(go.x+2)+'px', 'height':go.h+'px', 'width':go.w+"px", 'opacity':'0.0'},{duration:opt.speedrest,queue:false});
					
					canvas_come.animate({		'top':co.y+"px", 'left':co.x+'px', 'height':co.h+'px', 'width':co.w+"px"},{duration:(opt.speedrest-20),queue:false});
					
					bbox_go.animate({'opacity':0.0, 'top':go.y+"px", 'left':go.x+"px", 'height':go.h+'px',  'width':go.w+"px"},{duration:opt.speedrest,queue:false});
					
					bbox_come.animate({'opacity':0.9, 'top':co.y+"px", 'left':co.x+'px', 'height':co.h+'px', 'width':co.w+"px"},{duration:opt.speedrest,queue:false});		
					
					canvas_come.attr('src',main.find('li:eq('+opt.nextbanner+') img:first').attr('src'));
					
					
					main.find('li:eq('+opt.actbanner+') .creative_layer').clone().appendTo(main).addClass("topcreative");
					main.find('.topcreative').css({'position':'absolute','top':'0px','left':'0px','z-index':49,'width':opt.width+"px",'height':opt.height+"px"});
					
					textanim(main,opt.speedrest);
					
					// SET THE DELAY A BIT LONGER THAN STANDARD
					if (main.find('li:eq('+opt.actbanner+')').data('delayoffset') != undefined)
						opt.doffset=main.find('li:eq('+opt.actbanner+')').data('delayoffset');
					else
						opt.doffset=0;											
					
					
				},100);				
			}
			
			
			
			
			///////////////////////
			// ROTATE THE SLIDES //
			///////////////////////
			function rotateSlides(main,opt) {
				
				
				// CREATE SOME HELPER CONTAINER IN CASE THEY ARE NOT YET ADDED
				if (main.find('.canvas-go').length==0) {
					// FIRST CREATE SOME CANVASES
					main.append('<div><img style="position:absolute;left:0px;top:0px;z-index:10" class="canvas-go" src=""></div>');							
					main.append('<div class="blurholder"><img style="position:absolute;left:0px;top:0px;z-index:12" class="canvas-go-blur" src=""></div>');																
					main.append('<div class="blackbox-go" style="z-index:13;position:absolute;left:1px;top:1px;background-color:#000000;width:'+(opt.width-2)+'px;height:'+(opt.height-2)+'px"></div>');
					
					main.append('<div><img class="canvas-come" style="position:absolute;left:0px;top:0px;z-index:1" src=""></div>');
					main.append('<div class="blackbox-come" style="z-index:11;position:absolute;left:1px;top:1px;background-color:#000000;width:'+(opt.width-2)+'px;height:'+(opt.height-2)+'px"></div>');
				}
						
				// GET THE DIVS WE NEED
				var canvas_go=main.find('.canvas-go');												
				var canvas_go_blur=main.find('.canvas-go-blur');																		
				var canvas_come=main.find('.canvas-come');
				var bbox_go=main.find('.blackbox-go');
				var bbox_come=main.find('.blackbox-come');
										
				// SOURCE PREPEARING
				canvas_go.attr('src',main.find('li:eq('+opt.actbanner+') img:first').attr('src'));
				canvas_go_blur.attr('src',main.find('li:eq('+opt.actbanner+') img:first').attr('src'));

				// CALCULATE THE RANGES
				var ranges=getRange(opt,false,opt.direction);
				var go = ranges.go;
				var co = ranges.co;								
				
				// PREPARE THE BLACK BOXES (SHADOWS)
				bbox_go.css({'opacity':0,   'width':go.w+"px", 'height':go.h+"px", 'position':'absolute', 'top':go.y+'px', 'left':go.x+'px'});
				bbox_come.css({'opacity':1,	'width':co.w+"px", 'height':co.h+"px", 'position':'absolute', 'top':co.y+'px', 'left':co.x+'px'});										
				
				// OK ANIMATION IS ON
				opt.animateon = true;
				
				//RMOVE THE CREATIVE LAYERS FROM THE TOP
				main.find('.topcreative').animate({'opacity':'0.0'},{duration:100,queue:false});
				
				
				// WE NEED A LITTLE DELAY TO PREPARE THE ITEMS SO FAR
				setTimeout(function() {
				
					main.find('.topcreative').remove();
					main.removeClass('grab-cursor');
					
					// PREPARE THE ACTUAL DIVS HERE
					canvas_go.css({'opacity':1,		'width':go.w+"px", 'height':go.h+"px", 'position':'absolute', 'top':go.y+'px', 'left':go.x+'px'});
					canvas_go_blur.css({'opacity':0,'width':go.w+"px", 'height':go.h+"px", 'position':'absolute', 'top':go.y+'px', 'left':go.x+'px'});
					canvas_come.css({'opacity':1,	'width':co.w+"px", 'height':co.h+"px", 'position':'absolute', 'top':co.y+'px', 'left':co.x+'px'});
																														
					canvas_go.animate({	'opacity':1,		'top':go.y2+"px", 'left':go.x2+"px", 'height':go.h2+'px',  'width':go.w2+"px"},{duration:opt.speed,queue:false, complete:function() { opt.animateon=false; }});
					canvas_go_blur.animate({	'top':(go.y2+2)+"px", 'left':(go.x2+2)+'px', 'height':go.h2+'px', 'width':go.w2+"px", 'opacity':'0.8'},{duration:opt.speed,queue:false});
					
					canvas_come.animate({		'top':co.y2+"px", 'left':co.x2+'px', 'height':co.h2+'px', 'width':co.w2+"px"},{duration:(opt.speed-20),queue:false});
					
					bbox_go.animate({'opacity':0.9, 'top':go.y2+"px", 'left':go.x2+"px", 'height':go.h2+'px',  'width':go.w2+"px"},{duration:opt.speed,queue:false});
					
					bbox_come.animate({'opacity':0.0, 'top':co.y2+"px", 'left':co.x2+'px', 'height':co.h2+'px', 'width':co.w2+"px"},{duration:opt.speed,queue:false});		
					
					canvas_come.attr('src',main.find('li:eq('+opt.nextbanner+') img:first').attr('src'));
					
					
					main.find('li:eq('+opt.nextbanner+') .creative_layer').clone().appendTo(main).addClass("topcreative");
					main.find('.topcreative').css({'-webkit-user-select':'none','-khtml-user-select':'none','-moz-user-select':'none','-ms-user-select':'none','-o-user-select':'none','user-select':'none','position':'absolute','top':'0px','left':'0px','z-index':49,'width':opt.width+"px",'height':opt.height+"px"});
					textanim(main,opt.speed);
					setTimeout(function() {
						if (opt.grab=="on") main.addClass('grab-cursor');
					},opt.speed);
											
					
					
					

					// SET THE DELAY A BIT LONGER THAN STANDARD
					if (main.find('li:eq('+opt.nextbanner+')').data('delayoffset') != undefined)
						opt.doffset=main.find('li:eq('+opt.nextbanner+')').data('delayoffset');
					else
						opt.doffset=0;
						
					// SET NEXT BANNER TO THE ACTIVE BANNER
					opt.prevbanner=opt.actbanner;
					opt.actbanner=opt.nextbanner;
					opt.nextbanner = opt.nextbanner+1;
					if (opt.nextbanner>main.find('li').length-1) opt.nextbanner=0;	
					main.find('.minithumb').removeClass('selected');				
					main.find('#minithumb'+(opt.actbanner)).addClass('selected');	
					
					
				},100);				
			}
			
			
				///////////////////////////////////
				// CALCULATE RANGES OF MOVEMENTS //
				///////////////////////////////////
				function getRange(opt,md,direction) {
				
					var go={  x:0,y:0,h:0,x2:0,y2:0,h2:0,w:0,w2:0}
					var co={  x:0,y:0,h:0,x2:0,y2:0,h2:0,w:0,w2:0}
					
					
					// SET THE X AND Y POSITION OF THE MOUSE AND PAGE RELATIONS
					if (opt.mouseXoffset>opt.width/2) {
						var diffix = opt.pagex-opt.mouseXoffset;
						if (opt.pagex>opt.mouseXoffset) 
							diffix=0;
						else
							diffix=Math.abs(diffix);
						var procx = 1-(diffix/opt.width); 
					 } else {
						var procx = ((opt.pagex-opt.mouseXoffset)/(opt.width-opt.mouseXoffset)); 
					}
					
					
					if (opt.mouseYoffset>opt.height/2) {
						var diffiy = opt.pagey-opt.mouseYoffset;
						if (opt.pagey>opt.mouseYoffset) 
							diffiy=0;
						else
							diffiy=Math.abs(diffiy);
						var procy = 1-(diffiy/opt.height); 
					 } else {
						var procy = ((opt.pagey-opt.mouseYoffset)/(opt.height-opt.mouseYoffset)); 
					}
					
					if (md==false) {
						procx=1;
						procy=1;
					}
					
					//console.log('ProcX:'+procx+"  ProcY:"+procy);
					
					if (procx>1) procx=1;
					if (procy>1) procy=1;
					if (procy<0) procy=0;
					if (procx<0) procx=0;
					
					
					
					////////////////////////
					// MOVE IT DOWN BABY //
					///////////////////////
					if (direction=="down") {
							go.x = 0;	go.x2=0;	go.y = 0;	go.y2=opt.height;	go.h = opt.height;	go.h2=opt.height*0.13; 			go.w=opt.width;	go.w2=opt.width;
							co.x = 0;	co.x2=0;	co.y = 0;	co.y2=0;			co.h = 0;			co.h2=opt.height;	co.w=opt.width;	co.w2=opt.width;
							if (md) {					
								go.y = (go.y2) * procy;		
								go.h = (opt.height) * (1-procy);					
								co.y = (co.y2) * procy;		
								co.h = (opt.height) * procy;									
								opt.speedrest = opt.speed*(1-procy);
								opt.opaprocco = 1-procy;
								opt.opaprocgo = procy;
							}
							
							
							
					} else {
						
						////////////////////////////
						// OR MOVE IT UP ??      //
						//////////////////////////
						if (direction=="up") {
							go.x = 0;	go.x2=0;	go.y = 0;			go.y2=-2-opt.height*0.13;	go.h = opt.height;	go.h2=opt.height*0.13;			go.w=opt.width;	go.w2=opt.width;
							co.x = 0;	co.x2=0;	co.y = opt.height;	co.y2=0;	co.h = 0;			co.h2=opt.height;	co.w=opt.width;	co.w2=opt.width;
							if (md) {					
								go.y = go.y2*(1-procy);
								go.h = (go.h * procy) + (go.h2*(1-procy));
								co.y = opt.height - (opt.height * (1-procy));		
								co.h = (co.h2) * (1-procy);									
								opt.speedrest = opt.speed*(procy);
																
								opt.opaprocco = procy;
								opt.opaprocgo = 1-procy;
							}
						} else {
						
							//////////////////////////////
							// LET MOVE IT TO THE LEFT //
							////////////////////////////
							if (direction=="left") {
								go.x = 0;			go.x2=0;	go.y = 0;	go.y2=0;	go.h = opt.height;	go.h2=opt.height;	go.w=opt.width;	go.w2=0;
								co.x = opt.width;	co.x2=0;	co.y = 0;	co.y2=0;	co.h = opt.height;	co.h2=opt.height;	co.w=0;	co.w2=opt.width;
								if (md) {					
									go.x = go.x2*(1-procx);									
									go.w = (go.w * procx) + (go.w2*(1-procx));
									co.x = opt.width - (opt.width * (1-procx));		
									co.w = (co.w2) * (1-procx);									
									opt.speedrest = opt.speed*(procx);
																	
									opt.opaprocco = procx;
									opt.opaprocgo = 1-procx;
								}
								
							} else {
							
								//////////////////////////////
								// LET MOVE IT TO THE RIGHT //
								////////////////////////////
								go.x = 0;	go.x2=opt.width;	go.y = 0;	go.y2=0;	go.h = opt.height;	go.h2=opt.height;	go.w=opt.width;	go.w2=0;
								co.x = 0;	co.x2=0;			co.y = 0;	co.y2=0;	co.h = opt.height;	co.h2=opt.height;	co.w=0;	co.w2=opt.width;
								
								if (md) {			
									
									go.x = (go.x2) * procx;		
									go.w = (opt.width) * (1-procx);					
									co.x = (co.x2) * procx;		
									co.w = (opt.width) * procx;									
									opt.speedrest = opt.speed*(1-procx);
									opt.opaprocco = 1-procx;
									opt.opaprocgo = procx;
								}
							}
						}
					}
					
				 // IF WE HAVE MOUSE DOWN, WE NEED TO MOVE IT PROCENTUALY
				
				 
				 var ranges={};
				 ranges.go=go;
				 ranges.co=co;
				 return ranges;
				}
			
				///////////////////
				// TEXTANIMATION //
				//////////////////			
				function textanim(item,edelay) {
												
								var counter=0;
									
									item.find('.topcreative div').each(function(i) {
															
															var $this=$(this);
															
															// REMEMBER OLD VALUES
															if ($this.data('_top') == undefined) $this.data('_top',parseInt($this.css('top'),0));
															if ($this.data('_left') == undefined) $this.data('_left',parseInt($this.css('left'),0));
															if ($this.data('_op') == undefined) { $this.data('_op',$this.css('opacity'));}
															
													
															// CHANGE THE z-INDEX HERE
															$this.css({'z-index':1200});
															
															
																	
																	
																	
																	
																	//// -  FADE UP   -   ////
																	if ($this.hasClass('fadeup')) {
																			$this.animate({'top':$this.data('_top')+20+"px",
																							 'opacity':0},
																							{duration:0,queue:false})
																				   .delay(edelay + (counter+1)*350)
																				   .animate({'top':$this.data('_top')+"px",
																							 'opacity':$this.data('_op')},
																							{duration:500,queue:true})
																		counter++;
																	}
																	
																	
																	//// -  FADE RIGHT   -   ////
																	if ($this.hasClass('faderight')) {
																		$this.animate({'left':$this.data('_left')-20+"px",
																					 'opacity':0},
																					{duration:0,queue:false})
																		   .delay(edelay + (counter+1)*350)
																		   .animate({'left':$this.data('_left')+"px",
																					'opacity':$this.data('_op')},
																					{duration:500,queue:true})
																		counter++;
																	}
																	
																	
																	//// -  FADE DOWN  -   ////
																	if ($this.hasClass('fadedown')) {
																			$this.animate({'top':$this.data('_top')-20+"px",
																							 'opacity':0},
																							{duration:0,queue:false})
																				   .delay(edelay + (counter+1)*350)
																				   .animate({'top':$this.data('_top')+"px",
																							 'opacity':$this.data('_op')},
																							{duration:500,queue:true})
																		counter++;
																	}
																	
																	
																	//// -  FADE LEFT   -   ////
																	if ($this.hasClass('fadeleft')) {
																		$this.animate({'left':$this.data('_left')+20+"px",
																					 'opacity':0},
																					{duration:0,queue:false})
																		   .delay(edelay + (counter+1)*350)
																		   .animate({'left':$this.data('_left')+"px",
																					'opacity':$this.data('_op')},
																					{duration:500,queue:true})
																		counter++;
																	}
																	
																	//// -  FADE   -   ////
																	if ($this.hasClass('fade')) {
																		$this.animate({'opacity':0},
																					{duration:0,queue:false})
																		   .delay(edelay + (counter+1)*350)
																		   .animate({'opacity':$this.data('_op')},
																					{duration:500,queue:true})
																		counter++;
																	}
																	
																	
																	//// - WIPE UP/DOWN/LEFT/RIGHT - ////
																	if ($this.hasClass('wipeup') || $this.hasClass('wipedown') || $this.hasClass('wipeleft') || $this.hasClass('wiperight')) {
																		$this.animate({'opacity':0},{duration:0,queue:false});
																		setTimeout(function() {
																			if ($this.find('.wipermode').length==0) {
																				var actww=$this.outerWidth();
																				var acthh=$this.outerHeight();
																				var params={	
																							color:$this.css('backgroundColor'),
																							border:$this.css('border'),
																							
																							borderradiusmoz:$this.css('-moz-border-radius-topleft'),
																							borderradiusweb:$this.css('-webkit-border-top-left-radius'),
																							borderradius:$this.css('borderTopLeftRadius'),
																							
																							boxmoz:$this.css('-moz-box-shadow'),
																							boxweb:$this.css('-webkit-box-shadow'),
																							box:$this.css('box-shadow'),
																							
																							padtop:"0px",//$this.css('paddingTop'),
																							padleft:"0px",//$this.css('paddingLeft')
																							
																							paddingT:parseInt($this.css('paddingTop'),0),
																							paddingB:parseInt($this.css('paddingBottom'),0),
																							paddingL:parseInt($this.css('paddingLeft'),0),
																							paddingR:parseInt($this.css('paddingRight'),0),
																							
																							ww:actww + 30,
																							hh:acthh + 20
																						  };
																				$this.data('params',params);
																				
																				$this.wrapInner('<div style="position:absolute;overflow:hidden;width:'+(actww-(params.paddingL+params.paddingR))+'px;height:'+(acthh-(params.paddingT+params.paddingB))+'px;"><div class="wipermode-origin" style="top:0px;left:0px;position:absolute;width:'+actww+'px;height:'+acthh+'px;"></div></div>');			
																				$this.prepend('<div class="wipermode" style="width:'+actww+'px;height:'+acthh+'px;background-color:'+params.color+';top:0px;left:0px;position:absolute;border-radius:'+params.borderradius+';-moz-border-radius:'+params.borderradiusmoz+';-webkit-border-radius:'+params.borderradiusweb+';-moz-box-shadow:'+params.boxmoz+';-webkit-box-shadow:'+params.boxweb+';box-shadow:'+params.box+';"></div>');																				
																				$this.css({'background':'none'});																																								
																				
																			} 
																			
																			var params = $this.data('params');
																			// STOP ANIMATION, AND RESTORE ORIGINAL POSITION
																			$this.stop(true,true).find('.wipermode-origin')
																			$this.stop(true,true);
																			$this.find('.wipermode').stop(true,true);
																			

																			
																			
																			// REGISTER THE BG AND TEXT AT THE RIGHT POSITION (START POSITION)
																			if ($this.hasClass('wipeup')) {
																				$this.find('.wipermode-origin').css({'top':(-1*params.hh)+"px",'left':params.padleft});																			
																				$this.find('.wipermode').css({'top':(params.hh)+"px"});																				
																			} else {
																				if ($this.hasClass('wipedown')) {
																					$this.find('.wipermode-origin').css({'top':(params.hh)+"px",'left':params.padleft});																			
																					$this.find('.wipermode').css({'top':(-1*params.hh)+"px"});	
																				} else {
																					if ($this.hasClass('wipeleft')) {
																						$this.find('.wipermode-origin').css({'top':params.padtop,'left':(-1*params.ww)+"px"});																			
																						$this.find('.wipermode').css({'left':(params.ww)+"px"});	
																					} else {
																							$this.find('.wipermode-origin').css({'top':params.padtop,'left':(params.ww)+"px"});																			
																							$this.find('.wipermode').css({'left':(-1*params.ww)+"px"});	
																					}
																				}
																			}
																																						
																			$this.animate({'opacity':'1.0'},{duration:300,queue:false});
																			$this.find('.wipermode-origin').animate({'top':params.padtop, 'left':params.padleft},{duration:500,easing:'easeOutSine', queue:false});
																			$this.find('.wipermode').animate({'top':'0px','left':'0px'},{duration:500,easing:'easeOutExpo', queue:false});
																			
																		},(edelay + (counter+1)*350));
																		counter++;
																	}
																	
																	
																	//// - masklesswipe UP/DOWN/LEFT/RIGHT - ////
																	if ($this.hasClass('masklesswipeup') || $this.hasClass('masklesswipedown') || $this.hasClass('masklesswipeleft') || $this.hasClass('masklesswiperight')) {
																		$this.animate({'opacity':0},{duration:0,queue:false});
																		setTimeout(function() {
																			if ($this.find('.masklesswipemode').length==0) {
																				var actww=$this.outerWidth();
																				var acthh=$this.outerHeight();
																				var params={	
																							color:$this.css('backgroundColor'),
																							border:$this.css('border'),
																							
																							borderradiusmoz:$this.css('-moz-border-radius-topleft'),
																							borderradiusweb:$this.css('-webkit-border-top-left-radius'),
																							borderradius:$this.css('borderTopLeftRadius'),
																							
																							boxmoz:$this.css('-moz-box-shadow'),
																							boxweb:$this.css('-webkit-box-shadow'),
																							box:$this.css('box-shadow'),
																							
																							padtop:$this.css('paddingTop'),
																							padleft:$this.css('paddingLeft')
																						  };
																				$this.data('params',params);
																				$this.wrapInner('<div class="masklesswipemode-origin" style="top:0px;left:0px;position:absolute;width:'+actww+'px;height:'+acthh+'px;"></div>');			
																				$this.prepend('<div class="masklesswipemode" style="width:'+actww+'px;height:'+acthh+'px;background-color:'+params.color+';top:0px;left:0px;position:absolute;border-radius:'+params.borderradius+';-moz-border-radius:'+params.borderradiusmoz+';-webkit-border-radius:'+params.borderradiusweb+';-moz-box-shadow:'+params.boxmoz+';-webkit-box-shadow:'+params.boxweb+';box-shadow:'+params.box+';"></div>');																				
																				$this.css({'background':'none'});																																								
																				
																			} 
																			
																			var params = $this.data('params');
																			// STOP ANIMATION, AND RESTORE ORIGINAL POSITION
																			$this.stop(true,true).find('.masklesswipemode-origin')
																			$this.stop(true,true);
																			$this.find('.masklesswipemode').stop(true,true);
																			
																			var distance=50;
																			
																			// REGISTER THE BG AND TEXT AT THE RIGHT POSITION (START POSITION)
																			if ($this.hasClass('wipeup')) {
																				$this.find('.masklesswipemode-origin').css({'top':(-1*distance)+"px",'left':params.padleft});																			
																				$this.find('.masklesswipemode').css({'top':(distance)+"px"});																				
																			} else {
																				if ($this.hasClass('masklesswipedown')) {
																					$this.find('.masklesswipemode-origin').css({'top':(distance)+"px",'left':params.padleft});																			
																					$this.find('.masklesswipemode').css({'top':(-1*distance)+"px"});	
																				} else {
																					if ($this.hasClass('masklesswipeleft')) {
																						$this.find('.masklesswipemode-origin').css({'top':params.padtop,'left':(-1*distance)+"px"});																			
																						$this.find('.masklesswipemode').css({'left':(distance)+"px"});	
																					} else {
																							$this.find('.masklesswipemode-origin').css({'top':params.padtop,'left':(distance)+"px"});																			
																							$this.find('.masklesswipemode').css({'left':(-1*distance)+"px"});	
																					}
																				}
																			}
																																						
																			$this.animate({'opacity':'1.0'},{duration:800,queue:false});
																			$this.find('.masklesswipemode-origin').animate({'top':params.padtop, 'left':params.padleft},{duration:800,easing:'easeInExpo', queue:false});
																			$this.find('.masklesswipemode').animate({'top':'0px','left':'0px'},{duration:800,easing:'easeOutExpo', queue:false});
																			
																		},(edelay + (counter+1)*350));
																		counter++;
																	}
																	
															
														});	// END OF TEXT ANIMS ON DIVS
					
				}
			
			
			
			
			///////////////////////////
			// COUNT DOWN THE TIMER //
			//////////////////////////
			function countDown(main,opt) {
				opt.count=0;
				
				setInterval(function() {
							if ((opt.animateon==false && opt.mouseover==false) || (opt.animateon==false && opt.thumbclicked==true)) {
								opt.thumbclicked=false;
								opt.count++;
								if (opt.count >= opt.delay/100 + opt.doffset/100) {																																										
									opt.speed = opt.speedGood;
									rotateSlides(main,opt);
									opt.count=0;
								}
							}
				},100);
			}
})(jQuery);			


			   