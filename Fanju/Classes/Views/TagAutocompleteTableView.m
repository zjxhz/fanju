//
//  TagAutocompleteTableView.m
//  EasyOrder
//
//  Created by 徐 浣泽 on 1/24/13.
//
//

#import "TagAutocompleteTableView.h"

@interface TagAutocompleteTableView(){
    NSMutableArray* _matchedTags;
    UserTag* _newTag;
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
        [_autocompleteDelegate tagSelected:_newTag];
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
    
    if (_matchedTags.count == 0) {
        cell.textLabel.text = [NSString stringWithFormat:@"添加 “%@”", _newTag.name];
        cell.detailTextLabel.text = @"还没有人选过这个爱好呢，你很独特哦";
    } else{
        if(!_exactMatchFound && (!_exactMatchFound && indexPath.row == [self numberOfRowsInSection:0] - 1)){
            cell.textLabel.text = [NSString stringWithFormat:@"添加新标签 “%@”", _newTag.name];
        } else {
            UserTag* tag = [_matchedTags objectAtIndex:indexPath.row];
            cell.textLabel.text = tag.name;
            cell.detailTextLabel.text = @"";
        }
    }
    
    return cell;
    
}

-(BOOL)searchText:(NSString*)text{
    _matchedTags = [NSMutableArray array];
    _exactMatchFound = NO;
    for (UserTag* tag in _tags) {
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
        _newTag = [UserTag tagWithName:text];
    } else {
        _newTag = nil;
    }
    [self reloadData];
    return _matchedTags.count > 0;
}
@end
