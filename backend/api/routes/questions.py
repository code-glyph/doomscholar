"""Quiz question endpoints: graduate-level CV/ML (PSU CSE586, CSE584, CSE486–style)."""

import random
from typing import Optional

from fastapi import APIRouter
from pydantic import BaseModel

router = APIRouter()


# ── Response schemas ──────────────────────────────────────────────────────────


class MCQQuestion(BaseModel):
    """Multiple choice question: stem + options + index of correct answer (0-based)."""
    question: str
    options: list[str]
    correct_index: int  # 0-based index into options


class QuestionResponse(BaseModel):
    """A single question with hint, answer, and optional MCQ."""
    id: str
    topic: str
    hint: str
    answer: str
    mcq: Optional[MCQQuestion] = None


# ── Graduate-level questions (PSU CSE586/EE554, CSE584, CSE486–style) ────────────


COMPUTER_VISION_QUESTIONS: list[dict] = [
    # --- Core CNN / vision (CSE486-style) ---
    {
        "id": "cv-1",
        "topic": "Convolutional Neural Networks",
        "hint": "Think about how a small matrix slides over an image and computes dot products.",
        "answer": "A convolution is a mathematical operation where a kernel (small matrix) slides over an input (e.g. an image) and at each position we compute the element-wise product and sum the results, producing a feature map.",
        "mcq": {
            "question": "What does a convolution layer in a CNN learn to detect?",
            "options": [
                "Global image statistics",
                "Local patterns (edges, textures, shapes)",
                "Only the mean pixel value",
                "The exact pixel coordinates",
            ],
            "correct_index": 1,
        },
    },
    {
        "id": "cv-2",
        "topic": "Pooling",
        "hint": "This operation reduces spatial dimensions while keeping the most salient value in each region.",
        "answer": "Pooling (e.g. max pooling or average pooling) downsamples feature maps by dividing them into regions and taking one value per region (max or average), reducing spatial size and computation while providing translation invariance.",
        "mcq": {
            "question": "Max pooling primarily helps a CNN by:",
            "options": [
                "Increasing the number of parameters",
                "Reducing spatial dimensions and adding translation invariance",
                "Replacing all convolutions",
                "Storing every pixel value",
            ],
            "correct_index": 1,
        },
    },
    {
        "id": "cv-3",
        "topic": "Object Detection",
        "hint": "This metric compares predicted and ground-truth boxes.",
        "answer": "Single-stage detectors (e.g. YOLO, SSD) predict both class labels and bounding boxes in one forward pass; two-stage detectors (e.g. R-CNN) first propose regions then classify them. IoU measures overlap between predicted and ground-truth boxes.",
        "mcq": {
            "question": "In object detection, what does 'IoU' (Intersection over Union) measure?",
            "options": [
                "Image brightness",
                "Overlap between predicted and ground-truth bounding box",
                "Number of objects in the image",
                "Pixel resolution",
            ],
            "correct_index": 1,
        },
    },
    {
        "id": "cv-4",
        "topic": "Image Segmentation",
        "hint": "Semantic vs. instance: one labels by class only; the other also separates objects.",
        "answer": "Semantic segmentation assigns a class label to every pixel. Instance segmentation additionally separates different instances of the same class.",
        "mcq": {
            "question": "What is the main difference between semantic and instance segmentation?",
            "options": [
                "Semantic uses color, instance uses grayscale",
                "Semantic labels each pixel by class; instance also separates individual objects",
                "Instance is faster than semantic",
                "There is no difference",
            ],
            "correct_index": 1,
        },
    },
    {
        "id": "cv-5",
        "topic": "Feature Hierarchy in CNNs",
        "hint": "Early layers typically respond to simple patterns; deeper layers to more abstract ones.",
        "answer": "In CNNs, early layers learn low-level features (edges, corners); middle layers learn mid-level features (textures, parts); deeper layers learn high-level semantic features (objects, scenes).",
        "mcq": {
            "question": "In a typical CNN, deeper layers tend to capture:",
            "options": [
                "Only edge detectors",
                "Low-level features like edges and colors",
                "High-level semantic features (e.g. object parts, shapes)",
                "No meaningful features",
            ],
            "correct_index": 2,
        },
    },
    # --- CSE486: filtering, edges, geometry ---
    {
        "id": "cv-6",
        "topic": "Image Filtering and Convolution",
        "hint": "Linear operators applied to neighborhoods; smoothing reduces noise.",
        "answer": "Linear filtering applies a kernel in a sliding window; convolution is the same with the kernel flipped. Smoothing (e.g. Gaussian) reduces noise; gradients and Laplacians emphasize edges.",
        "mcq": {
            "question": "In image processing, convolution with a Gaussian kernel is primarily used for:",
            "options": [
                "Increasing contrast",
                "Smoothing and noise reduction",
                "Edge sharpening only",
                "Color space conversion",
            ],
            "correct_index": 1,
        },
    },
    {
        "id": "cv-7",
        "topic": "Edge and Corner Detection",
        "hint": "Corners have high curvature in two directions; edges in one.",
        "answer": "Edge detection uses gradients (e.g. Sobel) or zero-crossings of the Laplacian. Corner detection (e.g. Harris) looks for points where the gradient is strong in two directions, often via the structure tensor or Hessian.",
        "mcq": {
            "question": "Harris corner detection responds strongly to regions that have:",
            "options": [
                "Uniform intensity",
                "Strong gradient in one direction only",
                "Large gradient variation in two directions",
                "Low contrast",
            ],
            "correct_index": 2,
        },
    },
    {
        "id": "cv-8",
        "topic": "Laplacian of Gaussian (LoG)",
        "hint": "Combines smoothing and second derivative; scale is controlled by sigma.",
        "answer": "The Laplacian of Gaussian (LoG) is a blob detector: smooth with a Gaussian then apply the Laplacian. Zero-crossings or extrema correspond to edges or blobs at a scale determined by the Gaussian sigma.",
        "mcq": {
            "question": "The Laplacian of Gaussian (LoG) is commonly used for:",
            "options": [
                "Color normalization",
                "Edge and blob detection at a given scale",
                "Learning neural network weights",
                "Image compression",
            ],
            "correct_index": 1,
        },
    },
    {
        "id": "cv-9",
        "topic": "Camera Model and Projection",
        "hint": "Intrinsics (f, principal point) and extrinsics (R, t) map 3D to 2D.",
        "answer": "Camera intrinsics (focal length, principal point, skew) map 3D camera coordinates to 2D image coordinates. Extrinsics (rotation R, translation t) map world to camera frame. Together they form the projection matrix.",
        "mcq": {
            "question": "In the pinhole camera model, the matrix that contains focal length and principal point is called:",
            "options": [
                "The fundamental matrix",
                "The intrinsic matrix",
                "The homography matrix",
                "The essential matrix",
            ],
            "correct_index": 1,
        },
    },
    {
        "id": "cv-10",
        "topic": "Essential and Fundamental Matrix",
        "hint": "They encode the geometric relationship between two views; one is in calibrated space.",
        "answer": "The essential matrix E relates corresponding points in two calibrated cameras (E = [t]_x R). The fundamental matrix F does the same for uncalibrated cameras (F = K2^{-T} E K1^{-1}). Both encode epipolar geometry.",
        "mcq": {
            "question": "The essential matrix relates corresponding points in two views when:",
            "options": [
                "Only one camera is calibrated",
                "Both cameras are calibrated (intrinsics known)",
                "No calibration is needed",
                "Points are in the same image",
            ],
            "correct_index": 1,
        },
    },
    {
        "id": "cv-11",
        "topic": "Eight-Point Algorithm",
        "hint": "Linear algorithm to compute F or E from at least 8 point correspondences.",
        "answer": "The eight-point algorithm estimates the fundamental (or essential) matrix from at least eight point correspondences by setting up a linear system. Normalization of point coordinates improves numerical stability.",
        "mcq": {
            "question": "The eight-point algorithm is used to compute:",
            "options": [
                "Camera intrinsics from a single image",
                "The fundamental or essential matrix from point correspondences",
                "Optical flow only",
                "Image histograms",
            ],
            "correct_index": 1,
        },
    },
    {
        "id": "cv-12",
        "topic": "RANSAC and Robust Estimation",
        "hint": "Iteratively fit a model on random subsets and keep the fit with most inliers.",
        "answer": "RANSAC (Random Sample Consensus) repeatedly samples a minimal set of points, fits a model, and counts inliers. The model with the most inliers is refined (e.g. with all inliers) to get a robust estimate despite outliers.",
        "mcq": {
            "question": "RANSAC is primarily used to:",
            "options": [
                "Train deep networks",
                "Estimate model parameters robustly in the presence of outliers",
                "Smooth images",
                "Compute image gradients",
            ],
            "correct_index": 1,
        },
    },
    {
        "id": "cv-13",
        "topic": "Planar Homography",
        "hint": "A 3x3 matrix that maps points on a plane between two views.",
        "answer": "A homography H is a 3x3 matrix that describes the mapping between two images of a planar scene (or between two planes). It has 8 DOF and can be estimated from four point correspondences.",
        "mcq": {
            "question": "A planar homography can be estimated from how many point correspondences?",
            "options": [
                "2",
                "3",
                "4",
                "8",
            ],
            "correct_index": 2,
        },
    },
    # --- CSE586/EE554: probability, BoF, clustering ---
    {
        "id": "cv-14",
        "topic": "MLE and MAP Estimation",
        "hint": "MLE maximizes likelihood; MAP maximizes posterior (likelihood × prior).",
        "answer": "MLE chooses parameters that maximize the likelihood of the data. MAP chooses parameters that maximize the posterior p(θ|data) ∝ p(data|θ) p(θ), incorporating a prior and often acting as regularization.",
        "mcq": {
            "question": "In parameter estimation, MAP (maximum a posteriori) differs from MLE by:",
            "options": [
                "Using only the prior",
                "Incorporating a prior over parameters in addition to the likelihood",
                "Ignoring the data",
                "Using only one sample",
            ],
            "correct_index": 1,
        },
    },
    {
        "id": "cv-15",
        "topic": "Dirichlet Smoothing",
        "hint": "Used for categorical/Multinomial data to avoid zero probabilities.",
        "answer": "Dirichlet smoothing (e.g. Laplace smoothing) adds a prior (pseudo-counts) to categorical or multinomial counts so that unseen events get a small non-zero probability, improving robustness in BoF and language models.",
        "mcq": {
            "question": "Dirichlet smoothing in categorical/Multinomial estimation is used to:",
            "options": [
                "Increase the number of parameters",
                "Avoid zero probabilities for unseen categories (smoothing)",
                "Remove all priors",
                "Replace MLE with gradient descent only",
            ],
            "correct_index": 1,
        },
    },
    {
        "id": "cv-16",
        "topic": "Bag of Visual Words",
        "hint": "Quantize local features into visual words; represent image as histogram.",
        "answer": "Bag of (visual) features: extract local descriptors (e.g. SIFT), cluster them to form a visual codebook, quantize each descriptor to the nearest word, and represent each image as a histogram of visual word counts.",
        "mcq": {
            "question": "In bag-of-features for image classification, the 'visual codebook' is typically obtained by:",
            "options": [
                "Manual labeling",
                "Clustering (e.g. K-means) of local feature descriptors",
                "Random assignment",
                "Using only the first image",
            ],
            "correct_index": 1,
        },
    },
    {
        "id": "cv-17",
        "topic": "K-Means Clustering",
        "hint": "Alternate between assigning points to nearest center and recomputing centers.",
        "answer": "K-means alternates between (1) assigning each point to the nearest cluster center and (2) setting each center to the mean of its assigned points. It minimizes within-cluster sum of squared distances and is used in BoF codebook learning.",
        "mcq": {
            "question": "K-means clustering iteratively:",
            "options": [
                "Samples random subsets only",
                "Assigns points to nearest center, then updates centers as cluster means",
                "Uses only gradient descent",
                "Requires labels for each point",
            ],
            "correct_index": 1,
        },
    },
    {
        "id": "cv-18",
        "topic": "Gaussian Mixture Models and EM",
        "hint": "Mixture of Gaussians; E-step assigns soft membership, M-step updates parameters.",
        "answer": "A GMM models data as a mixture of K Gaussians. EM alternates E-step (compute posterior membership of each point to each component) and M-step (update means, covariances, and mixing weights). Used for soft clustering and in BoF.",
        "mcq": {
            "question": "In the EM algorithm for Gaussian mixture models, the E-step computes:",
            "options": [
                "Only the mean of the data",
                "Posterior membership (responsibility) of each point to each component",
                "Only the number of clusters",
                "The gradient of the loss",
            ],
            "correct_index": 1,
        },
    },
    {
        "id": "cv-19",
        "topic": "Mean Shift Clustering",
        "hint": "Mode-seeking: iteratively shift each point toward the local mean in feature space.",
        "answer": "Mean shift: each point is iteratively moved to the (weighted) mean of nearby points (e.g. in a kernel window), converging to modes of the density. No fixed K; number of clusters emerges from the data. Medoidshift uses medoids instead of means.",
        "mcq": {
            "question": "Mean shift clustering is best described as:",
            "options": [
                "A method that requires specifying K in advance",
                "A mode-seeking procedure that moves points toward local density peaks",
                "A method that only works in 1D",
                "A supervised classifier",
            ],
            "correct_index": 1,
        },
    },
    # --- CSE 584: ML (graphical models, deep learning, transformers) ---
    {
        "id": "cv-20",
        "topic": "Graphical Models",
        "hint": "Nodes are random variables; edges encode conditional dependence.",
        "answer": "Graphical models (Bayesian networks, Markov random fields) represent joint distributions via a graph: nodes are RVs, edges encode dependence. Inference (e.g. marginalization) can be exact (trees) or approximate (loopy belief propagation, sampling).",
        "mcq": {
            "question": "In a Bayesian network, the graph structure encodes:",
            "options": [
                "Only the mean of each variable",
                "Conditional independence relationships between random variables",
                "Only the number of samples",
                "Loss functions for training",
            ],
            "correct_index": 1,
        },
    },
    {
        "id": "cv-21",
        "topic": "Approximate Inference",
        "hint": "Exact inference is intractable in many graphs; we approximate marginals or MAP.",
        "answer": "When exact inference is intractable, we use approximate methods: variational inference (optimize a tractable surrogate), loopy belief propagation, or sampling (MCMC, Gibbs). Common in large graphical models and deep generative models.",
        "mcq": {
            "question": "Variational inference approximates the posterior by:",
            "options": [
                "Using only one sample",
                "Optimizing a tractable surrogate distribution to be close to the true posterior",
                "Ignoring the prior",
                "Using only the prior",
            ],
            "correct_index": 1,
        },
    },
    {
        "id": "cv-22",
        "topic": "Self-Supervised Learning",
        "hint": "Labels come from the data itself (e.g. next token, masked token, contrastive).",
        "answer": "Self-supervised learning creates supervisory signal from unlabeled data: e.g. predict masked tokens (BERT), next token (language modeling), or contrastive objectives (SimCLR, CLIP) so that similar pairs are close and dissimilar pairs are far.",
        "mcq": {
            "question": "In self-supervised learning, the training signal typically comes from:",
            "options": [
                "Human labels only",
                "The structure of the data itself (e.g. masking, contrastive pairs)",
                "Random noise only",
                "A single fixed label",
            ],
            "correct_index": 1,
        },
    },
    {
        "id": "cv-23",
        "topic": "Transformers and Attention",
        "hint": "Attention weights sum to one and allow each position to attend to others.",
        "answer": "Transformers use self-attention: each position computes a weighted combination of values from all positions, with weights (attention) from query-key similarity. This allows long-range dependencies without recurrent connections.",
        "mcq": {
            "question": "Self-attention in Transformers allows each token to:",
            "options": [
                "Attend only to the previous token",
                "Attend to all other positions (or a subset) with learned weights",
                "Only use the last hidden state",
                "Ignore the sequence order",
            ],
            "correct_index": 1,
        },
    },
    {
        "id": "cv-24",
        "topic": "Federated Learning",
        "hint": "Training on decentralized data; only gradients or model updates are shared.",
        "answer": "Federated learning trains a model across multiple clients (e.g. devices) without centralizing raw data. Clients compute local updates (gradients or model deltas); a server aggregates them to update the global model, preserving privacy.",
        "mcq": {
            "question": "Federated learning is characterized by:",
            "options": [
                "Centralizing all data on one server",
                "Training across distributed data while keeping raw data on local devices",
                "Using only one client",
                "Ignoring privacy",
            ],
            "correct_index": 1,
        },
    },
    {
        "id": "cv-25",
        "topic": "Deep Reinforcement Learning",
        "hint": "Agent takes actions in an environment; reward signal is often delayed.",
        "answer": "In deep RL, an agent learns a policy (often represented by a neural network) to maximize cumulative reward. Key ideas: value functions, policy gradient, Q-learning, and actor-critic methods; challenges include credit assignment and exploration.",
        "mcq": {
            "question": "In reinforcement learning, the agent learns to maximize:",
            "options": [
                "Only the immediate reward",
                "Cumulative (often discounted) reward over time",
                "Only the number of actions",
                "A single fixed target",
            ],
            "correct_index": 1,
        },
    },
    {
        "id": "cv-26",
        "topic": "Support Vector Machines",
        "hint": "Maximize the margin between classes; kernel trick gives non-linear boundaries.",
        "answer": "SVMs find the maximum-margin hyperplane that separates classes. The kernel trick allows implicit mapping to a high-dimensional space so that non-linear boundaries in the original space become linear in the feature space.",
        "mcq": {
            "question": "The 'kernel trick' in SVMs allows:",
            "options": [
                "Using only linear boundaries",
                "Implicit mapping to a high-dimensional space for non-linear decision boundaries",
                "Removing all parameters",
                "Using only one support vector",
            ],
            "correct_index": 1,
        },
    },
    {
        "id": "cv-27",
        "topic": "Image Pyramids",
        "hint": "Multi-scale representation: repeatedly smooth and downsample.",
        "answer": "An image pyramid is a multi-scale representation: each level is typically a low-pass filtered and downsampled version of the previous. Used for efficient multi-scale search, template matching, and coarse-to-fine alignment.",
        "mcq": {
            "question": "An image pyramid is primarily used for:",
            "options": [
                "Color enhancement only",
                "Multi-scale representation and coarse-to-fine processing",
                "Removing all high frequencies",
                "Storing only one resolution",
            ],
            "correct_index": 1,
        },
    },
    {
        "id": "cv-28",
        "topic": "Stereo Vision",
        "hint": "Two views; disparity is inverse related to depth.",
        "answer": "In stereo, two calibrated cameras view the same scene. Correspondence between left and right images gives disparity; depth is proportional to 1/disparity (plus baseline and focal length). Epipolar geometry constrains the search to a line.",
        "mcq": {
            "question": "In stereo vision, disparity is related to depth by:",
            "options": [
                "Disparity is proportional to depth",
                "Depth is inversely related to disparity (e.g. depth ∝ 1/disparity)",
                "Disparity is independent of depth",
                "Only one camera is used",
            ],
            "correct_index": 1,
        },
    },
    {
        "id": "cv-29",
        "topic": "Template Matching",
        "hint": "Slide a template over the image and compare (e.g. correlation, SSD).",
        "answer": "Template matching slides a template (patch) over the image and computes a similarity at each position (e.g. normalized cross-correlation, sum of squared differences). Often done in a pyramid for efficiency.",
        "mcq": {
            "question": "Normalized cross-correlation in template matching is used to:",
            "options": [
                "Train neural networks",
                "Measure similarity between template and image patch (invariant to brightness scale)",
                "Only detect edges",
                "Compress images",
            ],
            "correct_index": 1,
        },
    },
    {
        "id": "cv-30",
        "topic": "Categorical Distribution and MLE",
        "hint": "For discrete outcomes; MLE gives count proportions; Dirichlet prior gives smoothing.",
        "answer": "For categorical (multinomial) data, MLE of the category probabilities is the proportion of counts in each category. With a Dirichlet prior, the MAP estimate adds pseudo-counts (Dirichlet smoothing), avoiding zero probabilities.",
        "mcq": {
            "question": "For a categorical distribution, the MLE of the category probabilities is:",
            "options": [
                "Uniform for all categories",
                "The proportion of counts (relative frequency) in each category",
                "Always zero for unseen categories",
                "Independent of the data",
            ],
            "correct_index": 1,
        },
    },
]


def _to_response(item: dict) -> QuestionResponse:
    mcq = item.get("mcq")
    mcq_model = (
        MCQQuestion(
            question=mcq["question"],
            options=mcq["options"],
            correct_index=mcq["correct_index"],
        )
        if mcq
        else None
    )
    return QuestionResponse(
        id=item["id"],
        topic=item["topic"],
        hint=item["hint"],
        answer=item["answer"],
        mcq=mcq_model,
    )


# ── Endpoints ──────────────────────────────────────────────────────────────────


@router.get(
    "",
    response_model=QuestionResponse,
    summary="Get a random question",
    description="Returns one random computer vision question with hint, answer, and an MCQ.",
)
async def get_question() -> QuestionResponse:
    """Return a single random question (hint, answer, MCQ) on computer vision."""
    item = random.choice(COMPUTER_VISION_QUESTIONS)
    return _to_response(item)


@router.get(
    "/all",
    response_model=list[QuestionResponse],
    summary="List all questions",
    description="Returns all computer vision questions (e.g. for debugging or practice).",
)
async def list_questions() -> list[QuestionResponse]:
    """Return all sample questions."""
    return [_to_response(item) for item in COMPUTER_VISION_QUESTIONS]
