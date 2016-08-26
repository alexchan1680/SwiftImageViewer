# SwiftImageViewer
Easily customizable scaling Image Viewer &amp; View Controller written by Swift.

I am not sure whether this library is useful or not.

Platform: `XCode 8.0 beta 3, Swift3.0`

Purpose of this library is to write customized image view controllers easily.
Zooming and scrolling functionality is shared and you can display local image, image from network and animated gif images as well.

###  Quick Guide
  - In a word, you use this generic class to display image.
  
    ```swift
    public class SIVImageViewController<ImageView:SIVImageViewType, LoadingView:SIVImageLoadingIndicatorViewType where ImageView:UIView, LoadingView:UIView>: UIViewController
    ```
    
  - `SIVDefaultImageViewController` which uses `UIImageView` and `SIVDefaultImageLoadingView`
  
    ```swift
    public typealias SIVDefaultImageViewController = SIVImageViewController<UIImageView, SIVDefaultImageLoadingView>
    ```
    
Set `source` property of image view controller's property to display image.

Assign `barVisibiltyHandler` closure property to receive visibilty request (Bars toggle with single tap on image or hide on image zooming).
The signal is already throttled within 0.4 second interval and you can set bar's visibilty in this closure.

Please check example project.

### Features
- Make it possible to display not only static image but other type of image like animated gif 
  
   ```Swift
   public enum SIVImage{
      case image(UIImage)
      case data(Data, CGSize)
      
      // Image Size
      internal var size:CGSize {
        switch self {
        case let image(img):
            return img.size
        case let data(_, sz):
            return sz
        }
      }
      
      // Can make it public
      internal func toUIImage() -> UIImage?{
        switch self {
        case let image(img):
            return img
        case let data(dt, _):
            return UIImage(data: dt)
        }
      }
   }
   ```
- Can easily integrate any image resources with a few lines of code.
   Images can be loaded using [SDWebImage](https://github.com/rs/SDWebImage), [KingFisher](https://github.com/onevcat/Kingfisher) or some other libraries.
   Displaying these kinds of images is not so difficult.
   
   ```Swift
   
   /// Image Load Result with success & failed
   public enum SIVImageLoadResult{
       case success(SIVImage)
       case failed(ErrorProtocol?)
   }
   
   public protocol SIVImageSourceType {
       /// Cached Image, so before loading, check this property and display directly.
       var loadedImage:SIVImage? { get }
       
       /// Preview Image of image
       var previewImage:SIVImage? { get }   // Ability to support preview image
    
       /// Load function
       func load(progress:((Double) -> ())?, completion:((SIVImageLoadResult) -> ()))
    }
   ```
   
   You only need to write some kind of *`Wrapper Type`* that conforms `SIVImageSourceType`. 
   
   A simple `UIImage` wrapper type is like this
   ```Swift
   // MARK: Immediate Image Source
   struct ImmediateImageSource{
      var image:UIImage
   }

   extension ImmediateImageSource: SIVImageSourceType {
      var loadedImage:SIVImage?{
        return .image(image)
      }
      var previewImage:SIVImage?{
        return nil
      }
    
      func load(progress: ((Double) -> ())?, completion: ((SIVImageLoadResult) -> ())) {
        progress?(1.0)
        completion(.success(.image(image)))
      }
   }
   ```
   
   Check `DelayedImageSource` struct in example project to get idea about this.
   
-  Can use other view type than `UIImageView` to display image (e.g. [FLAnimatedImageView](https://github.com/Flipboard/FLAnimatedImage) )
    
   ```Swift
   public protocol SIVImageViewType: class {
     var sivImage:SIVImage? { get set }
   }
   ```
   
     - UIImageView example
      
       This is already done in this library
       
      ```Swift
      // MARK: - Conform to SIVImageViewType
      extension UIImageView:SIVImageViewType {
        public var sivImage:SIVImage? {
          get {
            return image.flatMap{.image($0)}
          }
          set {
            image = newValue?.toUIImage()
          }
        }
      }
      ```
      
       Try your self to make `FLAnimatedImageView` to conform `SIVImageViewType`. :smile:
       
       You can even use other type of view which can display image or animated image.
       
-  Easily integrate customized loading indicator
   
   ```Swift
   public protocol SIVImageLoadingIndicatorViewType: class {
      /// Set this property to update loading indicator view's progress.
      var progress:Double { get set }
    
      /// Loading Indicator view might have reload button, handler for it.
      var reloadHandler:SIVClosure? { get set }
    
      /// If Loading Indicator supports single tap for updating visibilty of control bar, implementing class can call this method
      var singleTapHandler:SIVClosure? { get set }
    
      /**
      Update with result, in case of success, this view will be removed from its superview so before doing it, there might be some animation
      */
      func update(withResult result:SIVImageLoadResult, completion:SIVClosure?)
    
      // Layout Size for this indicator view type
      static var layoutSize:SIVImageLoadingIndicatorViewSize { get }
  }
  
  
  public enum SIVImageLoadingIndicatorViewSize{
    case fullScreen         // This indicator fills whole screen
    case centered(CGSize)   // Indicator is centered with specific size.
    
    var autoresizingMask:UIViewAutoresizing {
        switch self {
        case .fullScreen:
            return [.flexibleWidth, .flexibleHeight]
        case .centered(_):
            return [.flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin]
        }
    }
  }
  ```
  
  Check `SIVDefaultImageLoadingView` class to get idea about how to write customized loading indicator.
  
  
### TODO List

- `FLAnimatedImageView` extension to conform `SIVImageViewType`
- `KingFisher` and `SDWebImage` wrapper `SIVImageSourceType`s
- Example using `UIPageViewController` to browse images.
- Example using `UICollectionViewController` and `UIPageViewController` to show custom transitions for photo browsing.



### License

- [MRProgress](https://github.com/mrackwitz/MRProgress)
    
    Library is using `MRProgress` library to implement `SIVDefaultImageLoadingView`
    
- MIT
