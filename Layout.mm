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
	/* alignLeft/alignCenter/alignRight bare keywords collide with the shared
	StringRoutines.C alignLeft(text,length) helper via OCframe's keyword
	table -- passthrough with the real Apple constant names sidesteps it. */
	if ( align && align->groupBody->gText )
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
		imageFrame = ::indentFrame([self frame],scale->getNumber());
	[viewImage setSize:imageFrame.size];
	if ( offset )
		imageFrame = *(NSRect*)offset->getPointer();
	[viewImage drawInRect:[self frame] fromRect:imageFrame operation:NSCompositeSourceOver fraction:1.0];
}

- (void)displayText
{
NSTextContainer 	*box = 0;
NSTextView 			*editor = 0;
NSRect 				indented = ::indentFrame([self frame],5.0);
GroupItem 			*align = base->get("align");
	//cout "displayText:",tag :;
	// Bare "object" resolves against the nearest in-scope GroupItem local (align,
	// declared just above) rather than "use base"'s target -- explicit base.object
	// is required here so the editor caches on the field being displayed, not on
	// its (optional) align attribute. A field with no "align" attribute would
	// otherwise null-deref the very next line down.
	if ( base->getObject() )
		editor = (NSTextView*)base->getObject();
	else {
		editor = [[NSTextView alloc] initWithFrame:indented];
		base->setObject((NSObject*)editor);
		[self addSubview:editor];
		}
	box = [editor textContainer];
	/* alignLeft/alignCenter/alignRight bare keywords collide with the shared
	StringRoutines.C alignLeft(text,length) helper via OCframe's keyword
	table -- passthrough with the real Apple constant names sidesteps it.
	case j means justify, how to set align justified??? */
	if ( align && align->groupBody->gText )
		if ( style->bgColor )
			[editor setBackgroundColor:style->bgColor];
		else	[editor setBackgroundColor:[NSColor clearColor]];
	[editor setFont:style->font];
	if ( style->selected )
		[editor setEditable:1];
	else	[editor setEditable:0];
	[editor setFrame:indented];
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
