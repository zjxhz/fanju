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
    NSMutableArray* _matchedTags;
    NSString* _newTag;
    BOOL _exactMatchFound;

}
@end
@implementation TagAutocompleteTableView

- (id)initWithFrame:(CGRect)frame style:(UITableViewStyle)style{
    self = [super initWithFrame:frame style:style];
    if (self) {
        _tags = [NSArray array];
        _matchedTags = [NSMutableArray array];
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
    return _matchedTags.count + (_newTag == nil ? 0 : 1);
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (_matchedTags.count == 0 || (!_exactMatchFound && indexPath.row == [self numberOfRowsInSection:0] - 1)) {
        [_autocompleteDelegate newTagSelected:_newTag];
    } else {
        [_autocompleteDelegate tagSelected:[_matchedTags objectAtIndex:indexPath.row]];
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
        UserTag* tag = [_matchedTags objectAtIndex:indexPath.row];
        cell.textLabel.text = tag.name;
    }
    
    return cell;
    
}

-(BOOL)searchText:(NSString*)text{
    _matchedTags = [NSMutableArray array];
    _exactMatchFound = NO;
    for (Tag* tag in _tags) {
        if ([tag.name caseInsensitiveCompare:text] == NSOrderedSame){
            _exactMatchFound  =  YES;
            [_matchedTags addObject:tag];
            continue;
        }
        if ([tag.name rangeOfString:text options:NSCaseInsensitiveSearch].location != NSNotFound) {
            [_matchedTags addObject:tag];
        }
    }
    if (_matchedTags.count == 0 || !_exactMatchFound) {
        _newTag = text;
    } else {
        _newTag = nil;
    }
    [self reloadData];
    return _matchedTags.count > 0;
}
@end
