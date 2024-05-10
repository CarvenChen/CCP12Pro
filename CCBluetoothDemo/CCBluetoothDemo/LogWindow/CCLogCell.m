//
//  CCLogCell.m
//  CCBluetoothDemo
//
//  Created by Carven on 2022/9/28.
//

#import "CCLogCell.h"
#import "Masonry.h"

@interface CCLogCell ()
@property (strong, nonatomic) UILabel *mContentLabel;
@end

@implementation CCLogCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self p_createUI];
    }
    return self;
}

- (void)p_createUI {
    self.backgroundColor = [UIColor clearColor];
    [self.contentView addSubview:self.mContentLabel];
    [self.mContentLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.equalTo(self.contentView).offset(10);
        make.right.bottom.equalTo(self.contentView).offset(-10);
    }];

}

- (void)setTextString:(NSString *)textString {
    _textString = textString;
    
    self.mContentLabel.text = textString;
}

#pragma mark - LazyLoad
- (UILabel *)mContentLabel {
    if (!_mContentLabel) {
        _mContentLabel = [[UILabel alloc] init];
        _mContentLabel.numberOfLines = 0;
        _mContentLabel.font = [UIFont systemFontOfSize:13];
    }
    return _mContentLabel;
}
@end
