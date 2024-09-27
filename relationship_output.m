% 打开并读取文件
filename = 'default_scenario_MessageGraphvizReport.txt';
fid = fopen(filename, 'r');
if fid == -1
    error('无法打开文件');
end

% 初始化一个Map来存储每个元素的关联关系
relationship_map = containers.Map('KeyType', 'char', 'ValueType', 'any');

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
                
                % 分别获取两端的元素
                left = sorted_pair{1};
                right = sorted_pair{2};
                
                % 更新左端的关联关系
                if isKey(relationship_map, left)
                    associated_values = relationship_map(left);
                    if ~ismember(right, associated_values)
                        relationship_map(left) = [associated_values, {right}];
                    end
                else
                    relationship_map(left) = {right};
                end
                
                % 更新右端的关联关系，确保对称
                if isKey(relationship_map, right)
                    associated_values = relationship_map(right);
                    if ~ismember(left, associated_values)
                        relationship_map(right) = [associated_values, {left}];
                    end
                else
                    relationship_map(right) = {left};
                end
            end
        end
    end
end

% 关闭文件
fclose(fid);

% 将结果写入到新的txt文件
output_filename = 'relationship_output.txt';
fid_out = fopen(output_filename, 'w');
if fid_out == -1
    error('无法创建输出文件');
end

% 获取所有的键，并写入文件
keys = relationship_map.keys;
for i = 1:length(keys)
    fprintf(fid_out, '%s:', keys{i});
    associated_values = relationship_map(keys{i});
    fprintf(fid_out, '%s', strjoin(associated_values, ';'));
    fprintf(fid_out, '\n');
end

% 关闭输出文件
fclose(fid_out);

disp(['结果已保存至 ', output_filename]);