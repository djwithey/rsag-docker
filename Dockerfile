FROM osrf/ros:jazzy-desktop

# Argument to allow network domain id to be set at build time
ARG NET_ID

# Environment
ENV ROS_DISTRO jazzy
ENV DEV_WS /app/practical_ws
ENV ROS_WS /opt/ros2_ws
ENV GAZEBO /usr/share/gazebo
ENV HOME /app
ENV DISPLAY host.docker.internal:0.0
ENV LIB_GL_ALWAYS_INDIRECT 0
ENV ROS_DOMAIN_ID ${NET_ID:-0}

# Set default terminal type
SHELL ["/bin/bash", "-c"]

# Install tools
RUN apt-get update && apt-get install -y \
      git \
      ros-$ROS_DISTRO-rqt-tf-tree \
      ros-$ROS_DISTRO-xacro \
      ros-dev-tools \
      python3-pip \
      python3-colcon-common-extensions \
      python-is-python3\
      python3-transforms3d \
#      python3-pyclean \
      python3-numpy \
      python3-matplotlib \
      curl \
      nautilus \
      iputils-ping \
      net-tools \
      wireless-tools \
      nano && \
      rm -rf /var/lib/apt/lists/*

# Install ROS package dependencies
RUN apt-get update && \
    rosdep update 

# Navigation2 and Gazebo
RUN apt-get update && apt-get install -y \
    ros-$ROS_DISTRO-joint-state-publisher-gui \
    ros-$ROS_DISTRO-navigation2 \
    ros-$ROS_DISTRO-nav2-bringup \
    ros-$ROS_DISTRO-slam-toolbox \
    ros-$ROS_DISTRO-turtlebot4-desktop \
    ros-$ROS_DISTRO-turtlebot4-msgs \
    ros-$ROS_DISTRO-turtlebot4-navigation \
    ros-$ROS_DISTRO-turtlebot4-node \
    ros-$ROS_DISTRO-turtlebot4-simulator \
    ros-$ROS_DISTRO-irobot-create-nodes \
    ros-$ROS_DISTRO-ros-gz

#RUN mkdir -p $ROS_WS/src
#WORKDIR $ROS_WS/src
#RUN apt-get update && git clone https://github.com/turtlebot/turtlebot4_simulator.git -b $ROS_DISTRO
#WORKDIR $ROS_WS
#RUN rosdep install --from-path src -yi
#RUN . /opt/ros/${ROS_DISTRO}/setup.bash; \
#        colcon build --symlink-install --parallel-workers 1

# Development code
RUN mkdir -p $DEV_WS/src
WORKDIR $DEV_WS/src
COPY ./practical_ws/src . 
COPY ./ros_entrypoint.sh /
# Generate SDF file
WORKDIR $DEV_WS/src/simple_robot_description/urdf
RUN . /opt/ros/${ROS_DISTRO}/setup.bash; \
        xacro simple_robot_gazebo.urdf.xacro > simple_robot_gazebo.urdf
RUN . /opt/ros/${ROS_DISTRO}/setup.bash; \
        gz sdf -p simple_robot_gazebo.urdf > ../sdf/simple_robot_gazebo.sdf
# Build and install
WORKDIR $DEV_WS
RUN . /opt/ros/${ROS_DISTRO}/setup.bash; \
        colcon build --symlink-install --parallel-workers 1

# Set up ROS source
RUN sed --in-place --expression \
      '$isource /opt/ros/'$ROS_DISTRO'/setup.bash' \
      /ros_entrypoint.sh
#RUN sed --in-place --expression \
#      '$isource '$ROS_WS'/install/setup.bash' \
#      /ros_entrypoint.sh
RUN sed --in-place --expression \
      '$isource '$DEV_WS'/install/setup.bash' \
      /ros_entrypoint.sh

      # Enable colcon_cd
RUN sed --in-place --expression \
      '$isource /usr/share/colcon_cd/function/colcon_cd.sh' \
      /ros_entrypoint.sh
RUN sed --in-place --expression \
      '$iexport _colcon_cd_root='$DEV_WS'' \
      /ros_entrypoint.sh

# Enable autocompletion colcon
RUN sed --in-place --expression \
      '$isource /usr/share/colcon_argcomplete/hook/colcon-argcomplete.bash' \
      /ros_entrypoint.sh



