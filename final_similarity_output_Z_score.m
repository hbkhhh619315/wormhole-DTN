% 打开并读取文件 abc.txt
filename_abc = 'connection_count.txt';
fid_abc = fopen(filename_abc, 'r');
if fid_abc == -1
    error('无法打开文件 abc.txt');
end

% 初始化存储每行的信息
lines = {};
values = [];

% 按行读取文件 abc.txt
while ~feof(fid_abc)
    % 读取每行并去掉首尾空格
    line = strtrim(fgetl(fid_abc));
    
    % 如果行不为空，处理它
    if ~isempty(line)
        % 去除空格
        line = regexprep(line, '\s+', '');
        
        % 提取"="后面的部分，并去除"次"
        parts = strsplit(line, '=');
        value_str = strtrim(parts{2});
        value_str = strrep(value_str, '次', '');  % 去掉"次"字
        
        % 将其转为数字类型
        value = str2double(value_str);
        
        % 将行和数值存储
        if value > 1
            lines{end+1} = line;
            values(end+1) = value;

        end
    end
end

% 关闭文件 abc.txt
fclose(fid_abc);

% % 计算平均值和标准差
% average_value = mean(values);
% std_dev = std(values);
% 
% % 使用 Z-Score 方法找出极端值
% threshold = 2; % 设置 Z-Score 阈值
% z_scores = (values - average_value) / std_dev;
% 
% % 筛选出 |Z| 大于 3 的极端值
% filtered_lines = {};
% for i = 1:length(lines)
%     if abs(z_scores(i)) > threshold
%         filtered_lines{end+1} = lines{i};
%     end
% end


% % 计算中位数和 MAD（中位数绝对偏差）
% median_value = median(values);
% MAD_value = median(abs(values - median_value));
% 
% if MAD_value == 0
%     MAD_value = 1e-9;  % 避免除零
% end
% 
% % 计算 Modified Z-Score
% MZ_Scores = 0.6745 * (values - median_value) / MAD_value;
% 
% % 设定阈值（一般 3.5 作为异常值阈值）
% threshold_MZ = 2;
% 
% % 筛选出异常值的行（使用 Modified Z-Score 替换 IQR）
% filtered_lines = {};
% for i = 1:length(lines)
%     if abs(MZ_Scores(i)) >= threshold_MZ
%         filtered_lines{end+1} = lines{i};
%     end
% end

% 取对数，避免大数值主导分布
log_values = log(values + 1);  % 避免 log(0) 错误

% 计算均值和标准差
log_median = median(log_values);
log_MAD = median(abs(log_values - log_median));

% 避免 MAD = 0 导致除零错误
if log_MAD == 0
    log_MAD = 1e-9;
end

% 计算 对数 Z-Score
log_Z_Scores = (log_values - log_median) / log_MAD;

% 设定阈值（一般 3 作为异常值阈值）
threshold_log_Z = 2;

% 筛选出异常值的行（使用 对数 Z-Score 替换 IQR）
filtered_lines = {};
for i = 1:length(lines)
    if abs(log_Z_Scores(i)) >= threshold_log_Z
        filtered_lines{end+1} = lines{i};
    end
end


% 打开并读取文件 def.txt
filename_def = 'relationship_output.txt';
fid_def = fopen(filename_def, 'r');
if fid_def == -1
    error('无法打开文件 def.txt');
end

% 初始化一个Map来存储 def.txt 文件中每个索引及其归属字符
def_map = containers.Map('KeyType', 'char', 'ValueType', 'any');

% 读取 def.txt 文件中的内容并存储到Map中
while ~feof(fid_def)
    % 读取每行并去掉首尾空格
    line = strtrim(fgetl(fid_def));
    
    % 如果行不为空，处理它
    if ~isempty(line)
        % 通过':'分割出索引和归属字符部分
        parts = strsplit(line, ':');
        source = strtrim(parts{1});
        destinations = strsplit(strtrim(parts{2}), ';');
        
        % 去除每个归属字符的多余空格
        destinations = strtrim(destinations);
        
        % 将结果存储到Map中
        def_map(source) = destinations;
    end
end

% 关闭文件 def.txt
fclose(fid_def);

% 初始化一个已处理的配对集合，防止重复计算
processed_pairs = containers.Map('KeyType', 'char', 'ValueType', 'logical');

% 打开输出文件
output_filename = 'final_similarity_output.txt';
fid_out = fopen(output_filename, 'w');
if fid_out == -1
    error('无法创建输出文件');
end

% 遍历所有满足条件的行
for i = 1:length(filtered_lines)
    % 提取“=”前的部分
    line = filtered_lines{i};
    parts = strsplit(line, '=');
    connection = strtrim(parts{1});
    
    % 提取"<->”前后的两个字符串
    elements = strsplit(connection, '<->');
    source_i = elements{1};
    source_j = elements{2};
    
    % 构造配对键，防止重复计算
    pair_key = strcat(source_i, '-', source_j);
    reverse_pair_key = strcat(source_j, '-', source_i);
    
    if isKey(processed_pairs, pair_key) || isKey(processed_pairs, reverse_pair_key)
        continue; % 如果已经处理过该配对，则跳过
    end
    
    % 查找 def_map 中的相关行
    if isKey(def_map, source_i) && isKey(def_map, source_j)
        destinations_i = def_map(source_i);
        destinations_j = def_map(source_j);
        
        % 计算相似字符个数
        common_chars = intersect(destinations_i, destinations_j);
        num_common = length(common_chars);
        
        % 计算相似度百分比
        similarity_i = (num_common / length(destinations_i)) * 100;
        similarity_j = (num_common / length(destinations_j)) * 100;
        
        % 将结果写入文件
        fprintf(fid_out, '%s:%d/%d=%.0f%%;%s:%d/%d=%.0f%%\n', ...
            source_i, num_common, length(destinations_i), similarity_i, ...
            source_j, num_common, length(destinations_j), similarity_j);
        
        % 标记为已处理
        processed_pairs(pair_key) = true;
    end
end

% 关闭输出文件
fclose(fid_out);

disp(['相似度分析结果已保存至 ', output_filename]);
