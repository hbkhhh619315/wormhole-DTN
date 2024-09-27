% 打开并读取文件
filename = 'default_scenario_MessageGraphvizReport.txt';
fid = fopen(filename, 'r');
if fid == -1
    error('无法打开文件');
end

% 初始化一个Map来存储每对连接符的统计次数
connection_map = containers.Map;

% 按行读取文件
while ~feof(fid)
    % 读取每行并去掉首尾空格
    line = strtrim(fgetl(fid));
    
    % 将该行的内容通过';'分割成多部分（防止一行有多个序列）
    sequences = strsplit(line, ';');
    
    for i = 1:length(sequences)
        % 对每个序列去掉首尾的空格
        sequence = strtrim(sequences{i});
        
        % 如果序列不为空，处理它
        if ~isempty(sequence)
            % 将序列通过'->'分割
            elements = strsplit(sequence, '->');
            
            % 遍历每个连接对
            for j = 1:length(elements)-1
                % 获取当前连接对
                pair = {elements{j}, elements{j+1}};
                
                % 排序连接对，确保a->b和b->a认为是等价的
                sorted_pair = sort(pair);
                key = strcat(sorted_pair{1}, '<->', sorted_pair{2});
                
                % 更新连接对的计数
                if isKey(connection_map, key)
                    connection_map(key) = connection_map(key) + 1;
                else
                    connection_map(key) = 1;
                end
            end
        end
    end
end

% 关闭文件
fclose(fid);

% 将结果写入到新的txt文件
output_filename = 'connection_count.txt';
fid_out = fopen(output_filename, 'w');
if fid_out == -1
    error('无法创建输出文件');
end

keys = connection_map.keys;
for i = 1:length(keys)
    fprintf(fid_out, '%s=%d次\n', keys{i}, connection_map(keys{i}));
end

% 关闭输出文件
fclose(fid_out);

disp(['结果已保存至 ', output_filename]);