#!/usr/bin/env bash
declare -A tokenizer_name_or_path
declare -A tokenizer_type
declare -A model_name_or_path
declare -A dataset_size

tokenizer_type["xlm"]="AutoTokenizer"
tokenizer_type["mbert"]="AutoTokenizer"
tokenizer_type["syllable"]="ThaiWordsSyllableTokenizer"
tokenizer_type["newmm"]="ThaiWordsNewmmTokenizer"
tokenizer_type["spm"]="ThaiRobertaTokenizer"
tokenizer_type["sefr"]="FakeSefrCutTokenizer"

tokenizer_name_or_path["xlm"]="xlm-roberta-base"
tokenizer_name_or_path["mbert"]="bert-base-multilingual-cased"
tokenizer_name_or_path["syllable"]="/ist/ist-share/scads/zo/thai2transformers/exp/syllable/tokenizer_folder"
tokenizer_name_or_path["newmm"]="/ist/ist-share/scads/zo/thai2transformers/exp/newmm/tokenizer_folder"
tokenizer_name_or_path["spm"]="/ist/ist-share/scads/zo/thai2transformers//exp_rerun/spm_lr_7e_4/tokenizer_folder"
tokenizer_name_or_path["sefr"]="/ist/ist-share/scads/zo/thai2transformers/exp/sefr_cut/tokenizer_folder"

model_name_or_path["xlm"]="xlm-roberta-base"
model_name_or_path["mbert"]="bert-base-multilingual-cased"
model_name_or_path["syllable"]="/ist/ist-share/scads/zo/thai2transformers/exp/syllable/output_folder/model/checkpoint-8000"
model_name_or_path["newmm"]="/ist/ist-share/scads/zo/thai2transformers/exp/newmm/output_folder/model/checkpoint-5000"
model_name_or_path["spm"]="/ist/ist-share/scads/zo/thai2transformers/exp_rerun/spm_lr_7e_4/output_folder/model/checkpoint-7000"
model_name_or_path["sefr"]="/ist/ist-share/scads/zo/thai2transformers/exp/sefr_cut/output_folder/model/checkpoint-4500"

dataset_size["thainer"]="5078"
dataset_size["lst20"]="67104"
dataset_size["dummytest"]="50"

output_base_dir=/ist/ist-share/scads/zo/thai2transformers/exp_finetune_fix_data_and_filtered_6
log_folder=/ist/ist-share/scads/zo/thai2transformers/log_exp_finetune_fix_data_and_filtered_6

if [ -e "$output_base_dir" ]; then
    echo "output_base_dir: $output_base_dir exist."
    while true; do
        read -p "Do you want to clear it out (y/n)?" answer
        case "$answer" in
            [Yy]* )
                rm -r "$output_base_dir"
                mkdir -p "$log_folder"
                break;;
            [Nn]* ) echo Quit; break;;
            * ) echo "Try again.";;
        esac
    done
else
    mkdir -p "$output_base_dir"
fi

if [ -e "$log_folder" ]; then
    echo "log_folder: $log_folder exist."
    while true; do
        read -p "Do you want to clear it out (y/n)?" answer
        case "$answer" in
            [Yy]* )
                rm -r "$log_folder"
                mkdir -p "$log_folder"
                break;;
            [Nn]* ) echo Quit; break;;
            * ) echo "Try again.";;
        esac
    done
else
    mkdir -p "$log_folder"
fi

declare -a base_models=("sefr" "xlm" "mbert")
declare -a dataset_names=("thainer" "lst20")
declare -a label_names=("ner_tags" "pos_tags")

effective_batch_size=32
device_batch_size=16

for dataset_name in "${dataset_names[@]}"
do
    for label_name in "${label_names[@]}"
    do
        for model in "${base_models[@]}"
        do
            EXP_NAME="${dataset_name}-${label_name}-${model}"
            log_path="${log_folder}/${EXP_NAME}.log"
            if [ -e "$log_path" ]; then
                echo "$log_path exist."
                continue
            fi
            touch "$log_path"
            echo "==================== Running Exp ===================="
            echo "${EXP_NAME}"
            echo "Tokenizer Type: ${tokenizer_type["${model}"]}"
            echo "Tokenizer Name or path: ${tokenizer_name_or_path["${model}"]}"
            echo "Model name or path: ${model_name_or_path["${model}"]}"
            echo "Training size: ${dataset_size["${dataset_name}"]}"
            echo "Warmup: $((("${dataset_size["${dataset_name}"]}" / "$effective_batch_size") * 6 / 10))"
            echo "Maxstep: $((("${dataset_size["${dataset_name}"]}" / "$effective_batch_size") * 6))"
            echo "Evalstep: $((("${dataset_size["${dataset_name}"]}" / "$effective_batch_size")))"
            echo "Output Dir: ${output_base_dir}/${EXP_NAME}"
            command="
                set -x
                python3 run_ner.py --tokenizer_type ${tokenizer_type["${model}"]} \
                --tokenizer_name_or_path ${tokenizer_name_or_path["${model}"]} \
                --model_name_or_path ${model_name_or_path["${model}"]} \
                --dataset_name ${dataset_name} \
                --lst20_data_dir ../data/input/datasets/LST20_Corpus \
                --label_name ${label_name} \
                --per_device_train_batch_size ${device_batch_size} \
                --per_device_eval_batch_size ${device_batch_size} \
                --gradient_accumulation_steps 1 \
                --learning_rate 3e-5 \
                --warmup_steps $((("${dataset_size["${dataset_name}"]}" / "$effective_batch_size") * 6 / 10))  \
                --logging_steps 10 \
                --eval_steps $((("${dataset_size["${dataset_name}"]}" / "$effective_batch_size"))) \
                --max_steps $((("${dataset_size["${dataset_name}"]}" / "$effective_batch_size") * 6)) \
                --evaluation_strategy steps \
                --output_dir $output_base_dir/$EXP_NAME \
                --do_train \
                --do_eval \
                --max_length 512 \
                --fp16 \
                --load_best_model_at_end \
                --seed 2020 \
                --filter_thainer_with_mbert_tokenizer_threshold 510
                "
                # script -q -c "long_running_command" /dev/null | print_progress
                script -q -c "bash -c ${command@Q}" /dev/null | tee "$log_path"
            sleep 0.5
        done
    done
done
