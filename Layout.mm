#import <Cocoa/Cocoa.h>
#import <string.h>
#import <stdio.h>
#import <stdlib.h>
#import "OCroutines.h"
#import "GroupItem.h"
#import "GroupBody.h"
#import "Stylish.h"
#import "GroupDraw.h"
#import "Layout.h"

@implementation Layout

- (void)displayCell
{
GroupItem 	*align = base->get("align");
NSString 	*tEXT = [NSString stringWithCString:base->getText() encoding:NSASCIIStringEncoding];
NSCell 		*cell = [textField cell];
	[cell initTextCell:tEXT];
	if ( align && align->groupBody->gText )
		switch (*align->groupBody->gText)
			{
			case 'c':
				[cell setAlignment:NSCenterTextAlignment];
				break;
			case 'l':
				[cell setAlignment:NSLeftTextAlignment];
				break;
			case 'r':
				[cell setAlignment:NSRightTextAlignment];
			}
	if ( style->fillColor )
		[textField setBackgroundColor:style->fillColor];
	[textField setTextColor:textColor];
	[[textField cell] setUsesSingleLineMode:1];
	[self addSubview:textField];
	if ( [cell isEditable] )
		if ( style->selected )
			{
			[[self window] makeFirstResponder:textField];
			[textField displayIfNeededIgnoringOpacity];
			}
}

- (void)displayImage
{
GroupItem 	*image = base->get("image");
GroupItem 	*offset = base->get("offset");
GroupItem 	*scale = base->get("scale");
NSImage 	*viewImage = (NSImage*)image->getObject();
NSRect 		imageFrame;
	if ( !viewImage )
		return;
	if ( scale )
		imageFrame = indentFrame([self frame],scale->getNumber());
	[viewImage setSize:imageFrame.size];
	if ( offset )
		imageFrame = *(NSRect*)offset->getPointer();
	[viewImage drawInRect:[self frame] fromRect:imageFrame operation:NSCompositeSourceOver fraction:1.0];
}

- (void)displayText
{
NSTextContainer 	*box = 0;
NSTextView 			*editor = 0;
NSRect 				indented = indentFrame([self frame],5.0);
GroupItem 			*align = base->get("align");
	//cout "displayText:",tag :;
	if ( align->getObject() )
		editor = (NSTextView*)align->getObject();
	else {
		editor = [[NSTextView alloc] initWithFrame:indented];
		align->setObject((NSObject*)editor);
		}
	box = [editor textContainer];
	if ( align && align->groupBody->gText )
		switch (*align->groupBody->gText)
			{
			case 'c':
				[editor setAlignment:NSCenterTextAlignment];
				break;
			case 'l':
				[editor setAlignment:NSLeftTextAlignment];
				break;
			case 'r':
				[editor setAlignment:NSRightTextAlignment];
			}
	// case j means justify, how to set align justified???
	if ( style->bgColor )
		[editor setBackgroundColor:style->bgColor];
	else	[editor setBackgroundColor:[NSColor clearColor]];
	[editor setFont:style->font];
	if ( style->selected )
		[editor setEditable:1];
	else	[editor setEditable:0];
	[editor setFrame:indented];
	if ( !style->subbed )
		{
		[self addSubview:editor];
		//cout "Font: " tag,editor.font.displayName :;
		style->subbed = 1;
		}
	//editor.displayIfNeededIgnoringOpacity();
}

- (void)drawRect:(NSRect)r
{
NSRect 	f;
	if ( !base )
		return;
	style = ::getStyle(base);
	[NSBezierPath setDefaultLineWidth:0.0];
	strokeColor = [NSColor blackColor];
	[strokeColor set];
	f = ::getFrame(base);
	f.origin.y = [self frame].size.height - f.origin.y - f.size.height;
	[layoutPath appendBezierPathWithRect:f];
	[layoutPath stroke];
}

- (Layout*)init:(GroupItem*)field
{
	base = field;
	layoutPath = [NSBezierPath bezierPath];
	return self;
}

- (NSPoint)invertY:(NSPoint)point
{
double 	baseY = [self frame].size.height - point.y;
	point.y = baseY;
	return point;
}

- (void)viewDidEndLiveResize
{
	::printf("View End resize\n");
	[self setFrame:[[self superview] frame]];
	//base.updateFrame(frame);
	[self setNeedsDisplay:1];
}

- (void)windowWillClose:(NSNotification*)notification
{
	::printf("Window closing: will exit\n");
	::exit(0);
}
@end
/*	Warning: the following methods were referenced but not declared
	indentFrame(NSRect,double)
*/
