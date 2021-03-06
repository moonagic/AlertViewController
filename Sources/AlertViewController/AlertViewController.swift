import UIKit

@available(iOSApplicationExtension, unavailable)
public class AlertViewController: UIViewController {
    private lazy var transitionDelegate = AlertTransition()
    
    public init() {
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .custom
        self.transitioningDelegate = self.transitionDelegate
    }
    
    @available(*, unavailable, message: "Please use one of the provided AlertController initializers")
    public required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    public func present(animated: Bool = true, completion: (() -> Void)? = nil) {
        let topViewController = UIViewController.topViewController()
        topViewController?.present(self, animated: animated, completion: completion)
    }
}

private class AlertTransition: NSObject, UIViewControllerTransitioningDelegate {
    
    private let dimmingViewColor = UIColor.black.withAlphaComponent(0.3)
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return PresentationController(presentedViewController: presented, presenting: presenting, dimmingViewColor: dimmingViewColor)
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return AnimationController(presentation: true)
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return AnimationController(presentation: false)
    }
}


private class PresentationController: UIPresentationController {
    
    private let dimmingView = UIView()
    
    init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?, dimmingViewColor: UIColor) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        self.dimmingView.backgroundColor = dimmingViewColor
    }
    
    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        
        self.presentingViewController.view.tintAdjustmentMode = .dimmed
        self.dimmingView.alpha = 0
        
        self.containerView?.addSubview(self.dimmingView)
        
        let coordinator = self.presentedViewController.transitionCoordinator
        coordinator?.animate(alongsideTransition: { _ in self.dimmingView.alpha = 1 }, completion: nil)
    }
    
    override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()
        
        self.presentingViewController.view.tintAdjustmentMode = .automatic
        
        let coordinator = self.presentedViewController.transitionCoordinator
        coordinator?.animate(alongsideTransition: { _ in self.dimmingView.alpha = 0 }, completion: nil)
    }
    
    override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        
        if let containerView = self.containerView {
            self.dimmingView.frame = containerView.frame
        }
    }
}


private class AnimationController: NSObject, UIViewControllerAnimatedTransitioning {
    
    private var isPresentation = false
    
    init(presentation: Bool) {
        self.isPresentation = presentation
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from), let toController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to), let fromView = fromController.view, let toView = toController.view else {
            return
        }
        
        if self.isPresentation {
            transitionContext.containerView.addSubview(toView)
        }
        
        let animatingController = self.isPresentation ? toController : fromController
        let animatingView = animatingController.view
        animatingView?.frame = transitionContext.finalFrame(for: animatingController)
        
        if self.isPresentation {
            animatingView?.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            animatingView?.alpha = 0
            MagicAnimator {
                animatingView?.transform = CGAffineTransform(scaleX: 1, y: 1)
                animatingView?.alpha = 1
            } completion: { finished in
                transitionContext.completeTransition(finished)
            }
        } else {
            MagicAnimator {
                animatingView?.alpha = 0
            } completion: { finished in
                fromView.removeFromSuperview()
                transitionContext.completeTransition(finished)
            }
        }
        
    }
    
    private func MagicAnimator(animations: @escaping () -> Void, completion: ((Bool) -> Void)? = nil) {
        UIView.animate(withDuration: 0, delay: 0, options: MagicAnimateOptionsValue, animations: animations, completion: completion)
    }

    /// This is a magic number
    let MagicAnimateOptionsValue = UIView.AnimationOptions(rawValue: 458880)
    
}

@available(iOSApplicationExtension, unavailable)
private extension UIViewController {
    class func topViewController(_ viewController: UIViewController? = nil) -> UIViewController? {
        let viewController = viewController ?? UIApplication.shared.keyWindow?.rootViewController
        if let navigationController = viewController as? UINavigationController, !navigationController.viewControllers.isEmpty {
            return self.topViewController(navigationController.viewControllers.last)
        } else if let tabBarController = viewController as? UITabBarController, let selectedController = tabBarController.selectedViewController {
            return self.topViewController(selectedController)
        } else if let presentedController = viewController?.presentedViewController {
            return self.topViewController(presentedController)
        }
        return viewController
    }
}
