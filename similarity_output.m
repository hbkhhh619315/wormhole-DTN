% 打开并读取文件
filename = 'relationship_output.txt';
fid = fopen(filename, 'r');
if fid == -1
    error('无法打开文件');
end

% 初始化一个Map来存储每个源及其归属字符
data_map = containers.Map('KeyType', 'char', 'ValueType', 'any');

% 按行读取文件
while ~feof(fid)
    % 读取每行并去掉首尾空格
    line = strtrim(fgetl(fid));
    
    % 如果行不为空，处理它
    if ~isempty(line)
        % 通过':'分割出源字符和归属字符部分
        parts = strsplit(line, ':');
        source = strtrim(parts{1});
        destinations = strsplit(strtrim(parts{2}), ';');
        
        % 去除每个归属字符的多余空格
        destinations = strtrim(destinations);
        
        % 将结果存储到Map中
        data_map(source) = destinations;
    end
end

% 关闭文件
fclose(fid);

% 获取所有的源字符
keys = data_map.keys;

% 初始化一个已处理过的配对集合，防止重复计算
processed_pairs = containers.Map('KeyType', 'char', 'ValueType', 'logical');

% 打开输出文件
output_filename = 'similarity_output.txt';
fid_out = fopen(output_filename, 'w');
if fid_out == -1
    error('无法创建输出文件');
end

% 计算每两个源之间的相似度
for i = 1:length(keys)
    source_i = keys{i};
    destinations_i = data_map(source_i);
    
    for j = i+1:length(keys)
        source_j = keys{j};
        destinations_j = data_map(source_j);
        
        % 构造配对键，防止重复计算
        pair_key = strcat(source_i, '-', source_j);
        reverse_pair_key = strcat(source_j, '-', source_i);
        
        if ~isKey(processed_pairs, pair_key) && ~isKey(processed_pairs, reverse_pair_key)
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
end

% 关闭输出文件
fclose(fid_out);

disp(['相似度分析结果已保存至 ', output_filename]);