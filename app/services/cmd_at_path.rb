class CmdAtPath
  def initialize(path)
    @path = path
  end

  def cmd(a_cmd)
    `cd #{@path} && #{a_cmd}`
  end
end
