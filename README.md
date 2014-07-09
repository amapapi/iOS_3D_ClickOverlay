iOS_3D_ClickOverlay
===================

MAMapKit 点击选中overlay

### 前述

- [高德官方网站申请key](http://id.amap.com/?ref=http%3A%2F%2Fapi.amap.com%2Fkey%2F).
- 阅读[参考手册](http://api.amap.com/Public/reference/iOS%20API%20v2_3D/).
- 如果有任何疑问也可以发问题到[官方论坛](http://bbs.amap.com/forum.php?gid=1).

### 使用教程

- ClickOverlay文件夹下的代码可以支持实现任意MAOverlay的点击，包括MAPolygon、MAPolyline、MACircle和自定义MAOverlay。
- 此处以实现MACircle点击为例。
- 创建SelectableOverlay，将MACircle作为其属性。
```objc
    MACircle *circle = [MACircle circleWithCenterCoordinate:CLLocationCoordinate2DMake(39.981892, 116.338255) radius:2000];
    SelectableOverlay * selectableCircle = [[SelectableOverlay alloc] initWithOverlay:circle];
```
- 将SelectableOverlay添加到mapView中。
```objc
    [self.mapView addOverlay:selectableCircle];
```
- 在mapView delegate的`-(MAOverlayView *)mapView:(MAMapView *)mapView viewForOverlay:(id <MAOverlay>)overlay`回调中，根据SelectableOverlay的选中状态和颜色属性设置overlayView。
```objc
 if ([overlay isKindOfClass:[SelectableOverlay class]])
 {
    SelectableOverlay * selectableOverlay = (SelectableOverlay *)overlay;
    id<MAOverlay> actualOverlay = selectableOverlay.overlay;
    if ([actualOverlay isKindOfClass:[MACircle class]])
    {
      /*根据SelectableOverlay的选中状态和颜色属性设置view。*/
      MACircleView *circleView = [[MACircleView alloc] initWithCircle:actualOverlay];
            
      circleView.lineWidth   = 4.f;
      circleView.strokeColor = selectableOverlay.isSelected ? selectableOverlay.selectedColor : selectableOverlay.regularColor;
      circleView.fillColor   = selectableOverlay.isSelected ? selectableOverlay.selectedColor : selectableOverlay.regularColor;
            
      return circleView;
    }
 }
```
- 在viewDidLoad中创建和添加手势。另外需实现手势的delegate方法，详见工程。
```objc
self.singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
self.singleTap.delegate = self;
[self.view addGestureRecognizer:self.singleTap];
// 需要额外添加一个双击手势，以避免当执行mapView的双击动作时响应两次单击手势。
self.doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:nil];
self.doubleTap.delegate = self;
self.doubleTap.numberOfTapsRequired = 2;
[self.view addGestureRecognizer:self.doubleTap];
```
- 在单击手势响应方法`-(void)handleSingleTap:(UITapGestureRecognizer *)theSingleTap`中，逆序遍历mapview中的SelectableOverlay，判断单击点touchLocation和SelectableOverlay的位置关系。
```objc
if ([overlay isKindOfClass:[SelectableOverlay class]])
{
  SelectableOverlay *selectableOverlay = overlay;
  /* 获取overlay对应的view. */
  MAOverlayPathView * View = (MAOverlayPathView *)[self.mapView viewForOverlay:selectableOverlay];
            
  /* 把屏幕坐标转换为MAMap坐标. */
  MAMapPoint mapPoint = MAMapPointForCoordinate([self.mapView convertPoint:touchLocation toCoordinateFromView:self.mapView]);
  /* overlay的线宽换算到MAMap坐标系的宽度. */
  double mapPointDistance = [self mapPointsPerPointInViewAtCurrentZoomLevel] * View.lineWidth;
              
  /* 判断是否选中了overlay. */
  if (isOverlayWithLineWidthContainsPoint(selectableOverlay.overlay, mapPointDistance, mapPoint) )
  {
    /* 设置选中状态. */
    selectableOverlay.selected = !selectableOverlay.isSelected;
                
    /* 修改view选中颜色. */
   View.fillColor   = selectableOverlay.isSelected? selectableOverlay.selectedColor:selectableOverlay.regularColor;
   View.strokeColor = selectableOverlay.isSelected? selectableOverlay.selectedColor:selectableOverlay.regularColor;
                
   /* 修改overlay覆盖的顺序. */
   [self.mapView exchangeOverlayAtIndex:idx withOverlayAtIndex:self.mapView.overlays.count - 1];
                
   /* 刷新显示*/
   [View setNeedsDisplay];
                
   *stop = YES;
   }
            
}
```
- 逆序遍历是考虑到Overlay相互重叠的情况，上层的overlay会优先被选中。
- 位置关系判断是通过调用`Utility`中提供的方法
```objc
BOOL isOverlayWithLineWidthContainsPoint(id<MAOverlay> overlay, double mapPointDistance, MAMapPoint mapPoint)
```
详见工程Demo文件夹。

### 架构

##### Controllers
- `<UIViewController>`
  * `BaseMapViewController` 地图基类
    - `ClickOverlayViewController` 点击选中overlay


##### Models

* `Conform to <MAOverlay>`
  - `SelectableOverlay` 自定义可选中的overlay(记录overlay选中状态,颜色属性)

##### Utility

* `Utility` 数学运算(计算点是否包含在overlay响应区域内)

### 截图效果

![selectCircle](https://raw.githubusercontent.com/cysgit/iOS_3D_ClickOverlay/master/iOS_3D_ClickOverlay/Resources/selectCircle.png)
![unselectCircle](https://raw.githubusercontent.com/cysgit/iOS_3D_ClickOverlay/master/iOS_3D_ClickOverlay/Resources/unselectCircle.png)

### 在线安装Demo

* `手机扫描如下二维码直接安装`

![qrcode](https://raw.githubusercontent.com/cysgit/iOS_3D_ClickOverlay/master/iOS_3D_ClickOverlay/Resources/qrcode.png)

* `手机上打开地址:<http://fir.im/clkOvly>`
