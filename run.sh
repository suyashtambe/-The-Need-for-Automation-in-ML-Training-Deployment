#!/bin/bash

# Define variables
DATA_DIR="/path/to/new_data"
MODEL_DIR="/path/to/models"
DEPLOY_DIR="/path/to/deployment"
GITHUB_REPO="https://github.com/yourusername/yourrepo.git"
LOG_FILE="training_log.txt"
MODEL_NAME="fraud_detection_model"
DATE=$(date +%Y-%m-%d_%H-%M-%S)
NEW_MODEL_PATH="$MODEL_DIR/$MODEL_NAME_$DATE.pkl"
BEST_MODEL_PATH="$MODEL_DIR/best_model.pkl"

# Step 1: Pull latest data (assuming it's in a Git repo)
echo "Fetching latest data..."
cd $DATA_DIR && git pull

# Step 2: Train the Model
echo "Training the model..."
python train_model.py --data $DATA_DIR --output $NEW_MODEL_PATH

# Step 3: Evaluate Model Performance
NEW_MODEL_SCORE=$(python evaluate_model.py --model $NEW_MODEL_PATH)
CURRENT_MODEL_SCORE=$(python evaluate_model.py --model $BEST_MODEL_PATH)

if (( $(echo "$NEW_MODEL_SCORE > $CURRENT_MODEL_SCORE" | bc -l) )); then
    echo "New model performs better. Deploying..."
    cp $NEW_MODEL_PATH $BEST_MODEL_PATH
    cp $BEST_MODEL_PATH $DEPLOY_DIR
    echo "$DATE - New model deployed with score: $NEW_MODEL_SCORE" >> $LOG_FILE
else
    echo "New model does not improve performance. Not deploying."
    rm $NEW_MODEL_PATH
fi

# Step 4: Archive old models
mkdir -p "$MODEL_DIR/archive"
mv $MODEL_DIR/*.pkl "$MODEL_DIR/archive/" 2>/dev/null

# Step 5: Push updates to GitHub
echo "Uploading to GitHub..."
cd $MODEL_DIR
git add .
git commit -m "Auto-update: Trained model on $DATE with score $NEW_MODEL_SCORE"
git push $GITHUB_REPO main

# Step 6: Generate a PDF report
python generate_report.py --log $LOG_FILE --output model_report.pdf

# Step 7: Upload PDF to GitHub
git add model_report.pdf
git commit -m "Added model training report $DATE"
git push
