//
//  CCLogViewController.m
//  CCBluetoothDemo
//
//  Created by Carven on 2022/9/28.
//

#import "CCLogViewController.h"
#import "CCLogCell.h"

@interface CCLogViewController ()<UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *logTableView;
@property (strong, nonatomic) NSMutableArray *logArray;
@end

@implementation CCLogViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.logTableView.dataSource = self;
    self.logTableView.delegate = self;
    
    self.logArray = [[[CClogManager sharedInstance] logs] copy];
    [self.logTableView reloadData];
//    [self.logTableView scrollToRowAtIndexPath:[NSIndexPath indexPathWithIndex:self.logArray.count - 1] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
}

- (IBAction)dismiss:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.logArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CCLogCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[CCLogCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    CCLogModel *model = [self.logArray objectAtIndex:indexPath.row];
    cell.textString = model.log;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
}
@end
