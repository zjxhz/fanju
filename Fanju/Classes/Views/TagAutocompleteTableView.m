//
//  TagAutocompleteTableView.m
//  EasyOrder
//
//  Created by 徐 浣泽 on 1/24/13.
//
//

#import "TagAutocompleteTableView.h"
#import "Tag.h"

@interface TagAutocompleteTableView(){
    NSMutableArray* _matchedTagNames;
    NSString* _newTag;
    BOOL _exactMatchFound;

}
@end
@implementation TagAutocompleteTableView

- (id)initWithFrame:(CGRect)frame style:(UITableViewStyle)style{
    self = [super initWithFrame:frame style:style];
    if (self) {
        _tags = [NSArray array];
        _matchedTagNames = [NSMutableArray array];
        self.scrollEnabled = YES;
        self.delegate = self;
        self.dataSource = self;
        self.backgroundColor = RGBCOLOR(0xF2, 0xF2, 0xF2);
    }
    return self;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return _matchedTagNames.count + (_newTag == nil ? 0 : 1);
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (_matchedTagNames.count == 0 || (!_exactMatchFound && indexPath.row == [self numberOfRowsInSection:0] - 1)) {
        [_autocompleteDelegate newTagSelected:_newTag];
    } else {
        [_autocompleteDelegate tagSelected:[_matchedTagNames objectAtIndex:indexPath.row]];
    }
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIdentifier = @"TagAutoCompletionCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    if(!_exactMatchFound && (!_exactMatchFound && indexPath.row == [self numberOfRowsInSection:0] - 1)){
        cell.textLabel.text = [NSString stringWithFormat:@"添加新标签 “%@”", _newTag];
    } else {
        NSString* tagName = [_matchedTagNames objectAtIndex:indexPath.row];
        cell.textLabel.text = tagName;
    }
    
    return cell;
    
}

-(BOOL)searchText:(NSString*)text{
    _matchedTagNames = [NSMutableArray array];
    _exactMatchFound = NO;
    for (id obj in _tags) {
        NSString* tagName = nil;
        if ([obj isKindOfClass:[Tag class]]) {
            Tag* tag = obj;
            tagName = tag.name;
        } else if([obj isKindOfClass:[NSString class]]){
            tagName = obj;
        }
        if ([tagName caseInsensitiveCompare:text] == NSOrderedSame){
            _exactMatchFound  =  YES;
            [_matchedTagNames addObject:tagName];
            continue;
        }
        if ([tagName rangeOfString:text options:NSCaseInsensitiveSearch].location != NSNotFound) {
            [_matchedTagNames addObject:tagName];
        }
    }
    if (_matchedTagNames.count == 0 || !_exactMatchFound) {
        _newTag = text;
    } else {
        _newTag = nil;
    }
    [self reloadData];
    return _matchedTagNames.count > 0;
}
@end
