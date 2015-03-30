class Array
  def latest_version
    max(&LATEST_VERSION_PROC)
  end

  def sort_by_version
    sort(&LATEST_VERSION_PROC)
  end

  LATEST_VERSION_PROC = proc { |app1, app2| app1[:version] <=> app2[:version] }
end
